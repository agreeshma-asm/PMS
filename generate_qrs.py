import qrcode
import os

def generate_machine_qrs():
    output_dir = "sample_qrs"
    os.makedirs(output_dir, exist_ok=True)
    
    machines = ["DAB1", "DAB2", "DAB3", "WIP"]
    
    for machine in machines:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=4,
        )
        qr.add_data(machine)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        path = os.path.join(output_dir, f"{machine}.png")
        img.save(path)
        print(f"Generated {path}")

if __name__ == "__main__":
    print("Generating sample machine QR codes...")
    generate_machine_qrs()
    print("Done!")
