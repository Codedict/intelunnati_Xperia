module Atm1 (
  input wire clk,
  input wire reset,
  input wire card_detected,
  input wire [3:0] pin,
  input wire [3:0] note,
  input wire [15:0] otp,
  input wire [15:0] withdrawal_amount,
  input wire [15:0] account_balance,
  input wire [15:0] mini_statement,
  output reg [15:0] display,
  output reg receipt,
  output reg account_blocked,
  output reg [15:0] balance,
  output reg [15:0] remaining_balance,
  output reg [15:0] mini_statement_reg
);

  // Constants
  parameter MAX_ATTEMPTS = 3;
  parameter WITHDRAWAL_LIMIT = 10000;
  parameter BLOCK_DURATION = 3;

  // States
  reg [3:0] state;
  reg [3:0] next_state;

  // Internal registers
  reg [3:0] pin_attempts;
  reg [15:0] withdrawal_balance;
  reg [15:0] total_withdrawals;
  reg [15:0] total_deposits;
  reg [3:0] block_counter;
  reg [15:0] deposit_amount;

  // Outputs
  reg [15:0] display_output;
  reg receipt_output;
  reg account_blocked_output;
  reg [15:0] balance_output;
  reg [15:0] remaining_balance_output;
  
  // State register
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= 4'b0000;
    end else begin
      state <= next_state;
    end
  end

  // State transitions and logic
  always @* begin
    case (state)
      4'b0000: // S_IDLE
        if (card_detected) begin
          next_state = 4'b0001; // S_SCAN_CARD
        end else begin
          next_state = 4'b0000;
        end
      4'b0001: // S_SCAN_CARD
        if (pin == 4'b0000) begin
          next_state = 4'b0010; // S_ENTER_PIN
          pin_attempts = 0;
        end else begin
          next_state = 4'b0001;
        end
      4'b0010: // S_ENTER_PIN
        if (pin == 4'b0000) begin
          next_state = 4'b0011; // S_TRANSACTION_TYPE
        end else if (pin_attempts < MAX_ATTEMPTS - 1) begin
          next_state = 4'b0010;
          pin_attempts = pin_attempts + 1;
        end else begin
          next_state = 4'b0100; // S_BLOCKED
          pin_attempts = 0;
        end
      4'b0011: // S_TRANSACTION_TYPE
        if (note[3]) begin
          next_state = 4'b0101; // S_WITHDRAW
        end else begin
          next_state = 4'b0110; // S_DEPOSIT_AMOUNT
        end
      4'b0101: // S_WITHDRAW
        if (withdrawal_amount <= WITHDRAWAL_LIMIT) begin
          next_state = 4'b0111; // S_AMOUNT_LESS_THAN_10000
          withdrawal_balance = withdrawal_amount;
          total_withdrawals = total_withdrawals + withdrawal_balance;
        end else begin
          next_state = 4'b1000; // S_AMOUNT_GREATER_THAN_10000
        end
      4'b0111: // S_AMOUNT_LESS_THAN_10000
        if (otp == 16'h1234) begin
          next_state = 4'b1001; // S_VALID_OTP
        end else begin
          next_state = 4'b1010; // S_INVALID_OTP
        end
      4'b1001: // S_VALID_OTP
        next_state = 4'b1100; // S_WITHDRAW_AMOUNT
      4'b1010: // S_INVALID_OTP
        next_state = 4'b1101; // S_WITHDRAW
      4'b1100: // S_WITHDRAW_AMOUNT
        next_state = 4'b1110; // S_PRINT_RECEIPT
      4'b1110: // S_PRINT_RECEIPT
        next_state = 4'b0000; // S_IDLE
      4'b0110: // S_DEPOSIT_AMOUNT
        if (deposit_amount > 0) begin
          next_state = 4'b0110;
          total_deposits = total_deposits + deposit_amount;
        end else begin
          next_state = 4'b1111; // S_TOTAL_DEPOSIT_AMOUNT
        end
      4'b1111: // S_TOTAL_DEPOSIT_AMOUNT
        next_state = 4'b0000; // S_IDLE
      4'b0100: // S_BLOCKED
        if (block_counter < BLOCK_DURATION - 1) begin
          next_state = 4'b0100;
          block_counter = block_counter + 1;
        end else begin
          next_state = 4'b0000; // S_IDLE
          block_counter = 0;
        end
      default:
        next_state = 4'b0000;
    endcase
  end

  // Display messages and outputs
  always @* begin
    display_output = (state == 4'b0000) ? "Welcome" :
                     (state == 4'b0001) ? "Please Insert Card" :
                     (state == 4'b0010) ? "Enter PIN" :
                     (state == 4'b0011) ? "Select Transaction" :
                     (state == 4'b0100) ? "Card Blocked" :
                     (state == 4'b0101) ? "Enter Amount" :
                     (state == 4'b0110) ? "Enter Amount" :
                     (state == 4'b0111) ? "Enter OTP" :
                     (state == 4'b1000) ? "Enter Amount" :
                     (state == 4'b1001) ? "Enter Amount" :
                     (state == 4'b1010) ? "Invalid OTP" :
                     (state == 4'b1100) ? "Printing Receipt" :
                     (state == 4'b1110) ? "Printed Receipt" :
                     (state == 4'b1111) ? "Deposit Success" : "Unknown";
  
    receipt_output = (state == 4'b1110) ? 1'b1 : 1'b0;
    account_blocked_output = (state == 4'b0100) ? 1'b1 : 1'b0;
    balance_output = (state == 4'b1111) ? total_deposits :
                     (state == 4'b1110) ? withdrawal_balance :
                     (state == 4'b0110) ? total_deposits :
                     (state == 4'b0111) ? 0 :
                     (state == 4'b0100) ? 0 : account_balance;
    remaining_balance_output = account_balance - withdrawal_balance;
  end

  // Assign outputs to registers
  always @(posedge clk) begin
    display <= display_output;
    receipt <= receipt_output;
    account_blocked <= account_blocked_output;
    balance <= balance_output;
    remaining_balance <= remaining_balance_output;
    mini_statement_reg <= mini_statement;
  end

endmodule
