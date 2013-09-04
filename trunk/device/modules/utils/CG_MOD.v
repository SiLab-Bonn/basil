
module CG_MOD_neg (ck_in, enable, ck_out);
    input ck_in,enable;
    output ck_out;
    reg enl;

        always @ (ck_in or enable)
        if (ck_in)
            enl = enable ;
        assign ck_out = ck_in | ~enl;
endmodule


module CG_MOD_pos (ck_in, enable, ck_out);
input ck_in,enable;
output ck_out;
wire ck_inb;
reg enl;

    assign ck_inb = ~ck_in;
    always @ (ck_inb or enable )
    if (ck_inb)
        enl = enable;
    assign ck_out = ck_in & enl;
    
endmodule
