def setup():
    import os
    
    os.system('clear')
    
    # Remove existing files (I'm sorry it has to be this way)
    for dirname in ["advent", "myth", "council", "justice"]:
        if os.path.exists(f"{dirname}/chain.json"):
            os.remove(f"{dirname}/chain.json")
        if os.path.exists(f"{dirname}/pool.json"):
            os.remove(f"{dirname}/pool.json")
        if os.path.exists(f"{dirname}/peers.txt"):
            os.remove(f"{dirname}/peers.txt")
        if os.path.exists(dirname):
            os.rmdir(dirname)