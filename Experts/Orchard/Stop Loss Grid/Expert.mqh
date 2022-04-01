/*

   GridTrader v1
   Expert

   Copyright 2022, Orchard Forex
   https://www.orchardforex.com

*/

/**=
 *
 * Disclaimer and Licence
 *
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * All trading involves risk. You should have received the risk warnings
 * and terms of use in the README.MD file distributed with this software.
 * See the README.MD file for more information and before using this software.
 *
 **/

#include "Framework.mqh"

class CExpert : public CExpertBase {

private:
protected:
   // Init values
   double mLevelSize;

   // Working values
   bool   mClosing;
   double mBuyPrice;
   double mSellPrice;
   double mExitPrice;
   double mLevelCount;

   void   Loop();

   void   ResetCounters();
   void   OpenGrid();
   void   CloseGrid();
   double OpenPosition( ENUM_ORDER_TYPE type );
   bool   ClosePosition( ENUM_POSITION_TYPE type );

   // For the demo, or if you want it
   void   DisplayLevels();
   void   DisplayLevel( string name, double value, string text );

public:
   CExpert( int    levelPoints, //
            double orderSize, string tradeComment, long magic );
   ~CExpert();
};

// As written this does not cope with restarting because all information is
//  inside variables that are lost on restart. To make this restartable
//  use global variables

CExpert::CExpert( int levelPoints, double orderSize, string tradeComment, long magic )
   : CExpertBase( orderSize, tradeComment, magic ) {

   mLevelSize = PointsToDouble( levelPoints );

   ResetCounters();

   mInitResult = INIT_SUCCEEDED;
}

CExpert::~CExpert() {
}

void CExpert::Loop() {

   //	This is here to make sure a close is a close
   if ( mClosing ) {
      CloseGrid();
      return;
   }

   // If there is nothing currently open then get started
   if ( mBuyPrice == 0 && mSellPrice == 0 ) {
      OpenGrid();
      return;
   }

   // I use SymbolInfoDouble ans pass in symbol instead of
   //  using inbuilt functions with defaults
   double bid = SymbolInfoDouble( mSymbol, SYMBOL_BID ); // Close price for buy
   double ask = SymbolInfoDouble( mSymbol, SYMBOL_ASK ); // close price for sell

   // If price has retreated to exit then close out
   if ( mExitPrice > 0 ) {
      if ( ( mBuyPrice > 0 && ask <= mExitPrice ) || ( mSellPrice > 0 && bid >= mExitPrice ) ) {
         CloseGrid();
         return;
      }
   }

   // If price has reached the next buy/sell price then shift up/down
   if ( ( mBuyPrice > 0 && bid >= mBuyPrice ) ) {
      // This can be made better in a trading sense
      // topic for another day
      mLevelCount++;
      mSellPrice = 0;

      if ( mLevelCount >= 4 ) {
         CloseGrid();
         // Optionally here shut down the expert because we may be in a trend
         //		Careful, this needs more
         Print( "Hit SL, stopping expert" );
         ExpertRemove();
      }
      else {
         if ( ClosePosition( POSITION_TYPE_BUY ) ) {
            mBuyPrice  = OpenPosition( ORDER_TYPE_BUY );
            mExitPrice = OpenPosition( ORDER_TYPE_SELL );
            if ( mBuyPrice == 0 || mExitPrice == 0 ) { // Something failed to open, shutdown
               CloseGrid();
            }
            else {
               mBuyPrice += mLevelSize;
               mExitPrice -= mLevelSize;
            }
            DisplayLevels();
         }
      }
      return;
   }

   if ( mSellPrice > 0 && ask <= mSellPrice ) {
      mLevelCount++;
      mBuyPrice = 0;

      if ( mLevelCount >= 4 ) {
         CloseGrid();
         // Optionally here shut down the expert because we may be in a trend
         //		Careful, this needs more
         Print( "Hit SL, stopping expert" );
         ExpertRemove();
      }
      else {
         if ( ClosePosition( POSITION_TYPE_SELL ) ) {
            mSellPrice = OpenPosition( ORDER_TYPE_SELL );
            mExitPrice = OpenPosition( ORDER_TYPE_BUY );
            if ( mSellPrice == 0 || mExitPrice == 0 ) { // Something failed to open, shutdown
               CloseGrid();
            }
            else {
               mSellPrice -= mLevelSize;
               mExitPrice += mLevelSize;
            }
            DisplayLevels();
         }
      }
      return;
   }

   return;
}

void CExpert::ResetCounters() {

   mClosing    = false;
   mBuyPrice   = 0; // Price to open next buy
   mSellPrice  = 0; // Price to open next sell
   mExitPrice  = 0; // Pullback price to close grid
   mLevelCount = 0; // How many levels deep

   DisplayLevels();
}

void CExpert::OpenGrid() {

   ResetCounters();

   // Just open in both directions
   mBuyPrice = OpenPosition( ORDER_TYPE_BUY );
   if ( mBuyPrice == 0 ) {
      Print( "Failed to open grid on buy" );
      CloseGrid(); // Big hammer approach
      return;
   }
   mBuyPrice += mLevelSize;

   mSellPrice = OpenPosition( ORDER_TYPE_SELL );
   if ( mSellPrice == 0 ) {
      Print( "Failed to open grid on sell" );
      CloseGrid(); // Big hammer approach
      return;
   }
   mSellPrice -= mLevelSize;

   DisplayLevels();
}

void CExpert::CloseGrid() {

   mClosing = !( ClosePosition( POSITION_TYPE_BUY ) && ClosePosition( POSITION_TYPE_SELL ) );

   if ( !mClosing ) {
      ResetCounters();
   }
}

double CExpert::OpenPosition( ENUM_ORDER_TYPE type ) {

   double price = ( type == ORDER_TYPE_BUY ) ? SymbolInfoDouble( mSymbol, SYMBOL_ASK )
                                             : SymbolInfoDouble( mSymbol, SYMBOL_BID );
   if ( Trade.PositionOpen( mSymbol, type, mOrderSize, price, 0, 0, mTradeComment ) ) {
      return ( Trade.ResultPrice() );
   }
   return ( 0 );
}

bool CExpert::ClosePosition( ENUM_POSITION_TYPE type ) {

   return ( Trade.PositionCloseByType( mSymbol, type ) );
}

void CExpert::DisplayLevels() {

   DisplayLevel( "BuyAt", mBuyPrice, "Buy At" );
   DisplayLevel( "SellAt", mSellPrice, "Sell At" );
   DisplayLevel( "ExitAt", mExitPrice, "Exit At" );
}

void CExpert::DisplayLevel( string name, double value, string text ) {

   string textName = name + "_text";
   ObjectDelete( 0, name );
   ObjectDelete( 0, textName );

   if ( value == 0 ) return;

   datetime time0 = iTime( mSymbol, mTimeframe, 0 );
   datetime time1 = iTime( mSymbol, mTimeframe, 1 );

   ObjectCreate( 0, name, OBJ_TREND, 0, time1, value, time0, value );
   ObjectSetInteger( 0, name, OBJPROP_HIDDEN, false );
   ObjectSetInteger( 0, name, OBJPROP_RAY_RIGHT, true );
   ObjectSetInteger( 0, name, OBJPROP_COLOR, clrYellow );

   ObjectCreate( 0, textName, OBJ_TEXT, 0, time0, value );
   ObjectSetInteger( 0, textName, OBJPROP_HIDDEN, false );
   ObjectSetString( 0, textName, OBJPROP_TEXT, StringFormat( text + " %f", value ) );
   ObjectSetInteger( 0, textName, OBJPROP_COLOR, clrYellow );

   return;
}