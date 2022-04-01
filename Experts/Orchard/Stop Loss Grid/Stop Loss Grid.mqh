/*

   Stop Loss Grid.mqh
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

//
//	Inputs
//

input int    InpLevelPoints  = 0; //	Trade gap in points

//	Now some general trading info
input double InpOrderSize    = 0.00;             //	Order size
input string InpTradeComment = "Stop Loss Grid"; //	Trade comment
input int    InpMagic        = 222222;           //	Magic number

#include "Expert.mqh"
CExpert *Expert;

int      OnInit() {

   Expert = new CExpert( InpLevelPoints, InpOrderSize, InpTradeComment, InpMagic );

   return ( Expert.InitResult() );
}

void OnDeinit( const int reason ) {

   delete Expert;
}

void OnTick() {

   Expert.OnTick();
   return;
}
