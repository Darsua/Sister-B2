# Sisters, Assemble

Why would you write a web server in assembly...

### GET

- Serves static files (HTML or other files).
- If the file has a `.html` extension, the server sends a `Content-Type: text/html` header.
- Other files are sent as downloads.
- NOTE: Only supports up to 1024 bytes.

**GET HTML**  
![GET HTML](docs/images/get_html.png)

**GET Image**
![GET Image](docs/images/get_img.gif)

**GET 404**
![GET 404](docs/images/get_404.png)

---

### POST to `/submit`

- Data sent to `/submit` is saved to `posts.txt`.
- Each entry is timestamped (using an external C function).
- Any other POST paths return a 405.

**POST**  
![POST](docs/images/post.gif)

---

### PUT

- Overwrites or creates a file at the requested path.
- NOTE: DOES NOT HAVE ANY SAFEGUARDS.

**PUT**
![PUT](docs/images/put.gif)

---

### DELETE

- Deletes the file at the requested path.
- NOTE: ALSO DOES NOT HAVE ANY SAFEGUARDS. This is even worse.

**DELETE**  
![DELETE Code Screenshot](docs/images/delete.gif)

---

## How to Build & Run

1. Build the server:
   
   ```
   make build
   ```

2. Run the server:
   
   ```
   make run
   ```

3. Clean build artifacts:
   
   ```
   make clean
   ```
