
function integer log2;
    input integer value;
    reg [31:0] shifted;
    integer res;
        begin
        if (value < 2)
          log2 = value;
        else
        begin
          shifted = value-1;
          for (res=0; shifted>0; res=res+1)
            shifted = shifted>>1;
          log2 = res;
        end
    end
endfunction