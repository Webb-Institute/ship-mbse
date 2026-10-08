function days = durationToDays(quantity, quantityUnit, rate, rateUnit)
%DURATIONTODAYS Time in days to use QUANTITY at RATE, with unit checking.
%   days = shipmbse.durationToDays(quantity, quantityUnit, rate, rateUnit)
%   divides quantity by rate and converts the result to days. The rate unit
%   must be "<quantityUnit>/<time>", where <time> is s, min, h or day,
%   e.g. quantity in "kL" with rate in "kL/s".
%
%   Errors with id shipmbse:durationToDays:UnitMismatch if the units are
%   not compatible.

arguments
    quantity double
    quantityUnit (1,1) string
    rate double
    rateUnit (1,1) string
end

parts = split(rateUnit, "/");
if numel(parts) ~= 2 || strtrim(parts(1)) ~= strtrim(quantityUnit)
    error("shipmbse:durationToDays:UnitMismatch", ...
        "Rate unit ""%s"" is not ""%s/<time>"".", rateUnit, quantityUnit);
end
secondsPer = dictionary(["s", "min", "h", "day"], [1, 60, 3600, 86400]);
timeUnit = strtrim(parts(2));
if ~isKey(secondsPer, timeUnit)
    error("shipmbse:durationToDays:UnitMismatch", ...
        "Unsupported time unit ""%s"" in ""%s"" (use s, min, h or day).", timeUnit, rateUnit);
end
days = (quantity ./ rate) * secondsPer(timeUnit) / 86400;

end
