var s := 'hello';
try
   StrToInt(s);
except
   on E: Exception do
	  PrintLn(E.Message);
end;
