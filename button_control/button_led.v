module button_led (
    input  wire key0,   // Push button (active-low)
    output wire led0    // LED output
);

    // LED on when button pressed
    assign led0 = ~key0;

endmodule
