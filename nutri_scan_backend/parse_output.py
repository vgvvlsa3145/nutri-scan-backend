with open('output.txt', 'r') as f:
    for line in f:
        if "ACTIVE" in line or "SUCCESS" in line:
            print(line.strip())
