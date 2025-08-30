import numpy as np
import matplotlib.pyplot as plt

# function: signed binary string -> signed decimal
def todecimal(x, bits):
    assert len(x) <= bits
    n = int(x, 2)
    s = 1 << (bits - 1)
    return (n & (s - 1)) - (n & s)

# parameters (must match your Verilog design)
N1 = 8   # coefficient bit width
N2 = 16  # input bit width
N3 = 32  # output bit width

# -------------------------------
# Read input data (N2-bit signed)
# -------------------------------
read_in = []
with open(r"input.data") as f:
    for line in f:
        read_in.append(line.strip())

input_signal = [todecimal(by, N2) / (2 ** (N1 - 1)) for by in read_in]

# -------------------------------
# Read output data (N3-bit signed)
# -------------------------------
read_out = []
with open(r"save.data") as f:
    for line in f:
        read_out.append(line.strip())

output_signal = [todecimal(by, N3) / (2 ** (2 * (N1 - 1))) for by in read_out]

# -------------------------------
# Plot both signals
# -------------------------------
plt.figure(figsize=(10,5))
plt.plot(input_signal, color='blue', linewidth=2, label='Input signal')
plt.plot(output_signal, color='red', linewidth=2, label='Filtered output')
plt.title("FIR Filter Input vs Output")
plt.xlabel("Sample index")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)
plt.savefig("results.png", dpi=600)
plt.show()
