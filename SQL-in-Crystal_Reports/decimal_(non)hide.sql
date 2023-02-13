// dicimal | ex. 1.00 = 1 / 9.99 = 9.99

stringVar number := ToText({Command.PriceBefDi}, 2);
while (right(number, 1) = "0") do number := left(number, len(number) - 1);
len(number) - InStr(number, ".");
