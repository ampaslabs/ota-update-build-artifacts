import subprocess

def is_systemd_service_running(service_name):
    """Checks if a systemd service is running."""
    try:
        subprocess.run(
            ["systemctl", "--quiet", "is-active", service_name],
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False

if __name__ == "__main__":
    service_name = "myapp"

    if is_systemd_service_running(service_name):
        print(f"{service_name} is running.")
    else:
        print(f"{service_name} is not running.")