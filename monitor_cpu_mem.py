import psutil
import time

def get_cpu_usage():
    return psutil.cpu_percent(interval=1)

def get_memory_usage():
    mem = psutil.virtual_memory()
    return {
        'total': mem.total,
        'available': mem.available,
        'used': mem.used,
        'percent': mem.percent
    }

def main():
    try:
        while True:
            cpu_usage = get_cpu_usage()
            memory_usage = get_memory_usage()

            print(f"CPU Usage: {cpu_usage}%")
            print(f"Memory Usage: {memory_usage['used'] / (1024 ** 3):.2f} GB / {memory_usage['total'] / (1024 ** 3):.2f} GB ({memory_usage['percent']}%)")

            time.sleep(5)  # Adjust the interval as needed
            print("\033c")  # Clear the console for a cleaner output (works on Linux)

    except KeyboardInterrupt:
        print("Monitoring stopped.")

if __name__ == "__main__":
    main()
