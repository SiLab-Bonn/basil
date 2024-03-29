##---------------------------------------------------------------------
##--                                                                 --
##-- Company:  University of Bonn                                    --
##-- Engineer: John Bieling                                          --
##--                                                                 --
##---------------------------------------------------------------------
##--                                                                 --
##-- Copyright (C) 2015 John Bieling                                 --
##--                                                                 --
##-- This program is free software; you can redistribute it and/or   --
##-- modify it under the terms of the GNU General Public License as  --
##-- published by the Free Software Foundation; either version 3 of  --
##-- the License, or (at your option) any later version.             --
##--                                                                 --
##-- This program is distributed in the hope that it will be useful, --
##-- but WITHOUT ANY WARRANTY; without even the implied warranty of  --
##-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    --
##-- GNU General Public License for more details.                    --
##--                                                                 --
##-- You should have received a copy of the GNU General Public       --
##-- License along with this program; if not, see                    --
##-- <http://www.gnu.org/licenses>.                                  --
##--                                                                 --
##---------------------------------------------------------------------

#TIMEGRP "SFCounter" = ffs("*/SFC_*");
#TIMESPEC TS_SlimFastCounter = FROM "SFCounter" TO "SFCounter" 40 ns;
# We should have up to 8 cycles to do this computation, as the fast count has 3 bits
set_multicycle_path -setup -from [get_pins -hier *SFC_*/C] -to [get_pins -hier *SFC_*/D] 8;
set_multicycle_path -hold -end -from [get_pins -hier *SFC_*/C] -to [get_pins -hier *SFC_*/D] 7;

