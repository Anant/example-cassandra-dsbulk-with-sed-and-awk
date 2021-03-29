function round(x, ival, aval, fraction){
   ival = int(x)    # integer part, int() truncates

   # see if fractional part
   if (ival == x)   # no fraction
      return ival   # ensure no decimals

   if (x < 0) {
      aval = -x     # absolute value
      ival = int(aval)
      fraction = aval - ival
      if (fraction >= .5)
         return int(x) - 1   # -2.5 --> -3
      else
         return int(x)       # -2.3 --> -2
   } else {
      fraction = x - ival
      if (fraction >= .5)
         return ival + 1
      else
         return ival
   }
}


BEGIN{OFS=","}
{
    gsub(/[-:T]/," ",$4);
    gsub(/[\s..Z]/,"",$4);
    gsub(/[-:T]/," ",$5);
    gsub(/[\s..Z]/,"",$5);
    first_day = mktime($4)
    last_day = mktime($5)
    print $1, $2, $3, round((last_day-first_day)/86400) < 0 ? round((last_day-first_day)/86400) * -1 : round((last_day-first_day)/86400)
}