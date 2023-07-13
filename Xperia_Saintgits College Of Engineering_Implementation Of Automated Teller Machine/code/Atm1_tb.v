module Atm1_tb;

  // Inputs
  reg clk;
  reg reset;
  reg card_detected;
  reg [3:0] pin;
  reg [3:0] note;
  reg [15:0] otp;
  reg [15:0] withdrawal_amount;
  reg [15:0] account_balance;
  reg [15:0] mini_statement;
  reg [15:0] deposit_amount; // Added declaration

  // Outputs
  wire [15:0] display;
  wire receipt;
  wire account_blocked;
  wire [15:0] balance;
  wire [15:0] remaining_balance;
  wire [15:0] mini_statement_reg;

  // Instantiate the DUT
  Atm1 dut (
    .clk(clk),
    .reset(reset),
    .card_detected(card_detected),
    .pin(pin),
    .note(note),
    .otp(otp),
    .withdrawal_amount(withdrawal_amount),
    .account_balance(account_balance),
    .mini_statement(mini_statement),
    .display(display),
    .receipt(receipt),
    .account_blocked(account_blocked),
    .balance(balance),
    .remaining_balance(remaining_balance),
    .mini_statement_reg(mini_statement_reg)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Initialize inputs
  initial begin
    clk = 0;
    reset = 1;
    card_detected = 0;
    pin = 0;
    note = 0;
    otp = 0;
    withdrawal_amount = 0;
    account_balance = 1000; // Initial account balance
    mini_statement = 0;
    deposit_amount = 0; // Initialize deposit_amount

    // Reset
    #10 reset = 0;

    // Test case 1: Successful withdrawal
    #20 card_detected = 1;
    #10 pin = 0;
    #10 pin = 0;
    #10 pin = 0;
    #10 note = 4'b1000;
    #10 withdrawal_amount = 500;
    #10 otp = 16'h1234;
    #100;
    
    // Test case 2: Invalid OTP
    #20 card_detected = 1;
    #10 pin = 0;
    #10 pin = 0;
    #10 pin = 0;
    #10 note = 4'b1000;
    #10 withdrawal_amount = 500;
    #10 otp = 16'h1111;
    #100;

    // Test case 3: Deposit
    #20 card_detected = 1;
    #10 pin = 0;
    #10 pin = 0;
    #10 pin = 0;
    #10 note = 4'b0001;
    #10 deposit_amount = 200;
    #100;

    // Add more test cases as needed...

    // End simulation
    #10 $finish;
  end

endmodule
