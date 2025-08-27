.intel_syntax noprefix

.extern write_timestamp

# -----------------------------------------------------------
.section .data
# -----------------------------------------------------------

# --- SYSTEM CALLS ---
SYS_socket = 41
SYS_bind = 49
SYS_listen = 50
SYS_accept = 43

SYS_read = 0
SYS_write = 1
SYS_open = 2
SYS_close = 3

SYS_fork = 57
SYS_exit = 60
SYS_unlink = 87
SYS_rt_sigaction = 13


# --- SIGNALS ---
SIGINT = 2

# Signal action struct
.align 8
sigaction:
    .quad signal_handler
    .quad 0
    .quad 0, 0
    .zero 128


# --- SOCKET ---
AF_INET=2
SOCK_STREAM=1

# Socket address struct
sockaddr:
    .word AF_INET
    .byte 0x1e, 0x61 # Port (7777)
    .byte 0, 0, 0, 0 # IP
    .zero 8 # Padding to make it 16 bytes


# --- HTTP RESPONSES ---
http_header_html: .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
http_header_html_len = . - http_header_html

http_header_download: .asciz "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Disposition: attachment\r\n\r\n"
http_header_download_len = . - http_header_download

method_not_allowed_header: .asciz "HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/html\r\n\r\n"
method_not_allowed_header_len = . - method_not_allowed_header

file_not_found_header: .asciz "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\n\r\n"
file_not_found_header_len = . - file_not_found_header

internal_server_error_header: .asciz "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/html\r\n\r\n"
internal_server_error_header_len = . - internal_server_error_header

bad_request_header: .asciz "HTTP/1.1 400 Bad Request\r\nContent-Type: text/html\r\n\r\n"
bad_request_header_len = . - bad_request_header


# --- HTTP METHODS ---
method_get: .asciz "GET"
method_post: .asciz "POST"
method_put: .asciz "PUT"
method_delete: .asciz "DELETE"


# --- PATHS ---
submit_path: .asciz "submit"
posts_path: .asciz "posts.txt"


# --- EXTRA ---
space: .asciz "\n\n"


# -----------------------------------------------------------
.section .bss
# -----------------------------------------------------------

socket: .quad 0 # Host socket file descriptor
client: .quad 0 # Client socket file descriptor

buffer_recv: .space 1024 # Buffer for reading requests
buffer_send: .space 1024 # Buffer for sending responses

method: .space 8 # Buffer for storing the request method
path: .space 256 # Buffer for storing the requested path


# -----------------------------------------------------------
.section .text
# -----------------------------------------------------------

# --- SIGNAL HANDLER FOR SHUTDOWN ---
signal_handler:
    # Close the server socket
    mov rax, SYS_close
    mov rdi, socket
    syscall ## close(socket)

    # Exit the process
    mov rax, SYS_exit
    xor rdi, rdi
    syscall ## exit(0)


# --- MAIN SERVER LOOP ---
.global _start
_start:
    # Set up signal handler for SIGINT
    mov rax, SYS_rt_sigaction
    mov rdi, SIGINT
    lea rsi, sigaction
    xor rdx, rdx
    syscall ## rt_sigaction(SIGINT, &sigaction, NULL, 8)

    # Create a socket
    mov rax, SYS_socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall ## socket(AF_INET, SOCK_STREAM, 0)
    mov socket, rax # Save socket fd

    # Bind the socket
    mov rax, SYS_bind
    mov rdi, socket
    lea rsi, sockaddr
    mov rdx, 16 # sizeof(sockaddr)
    syscall ## bind(socket, &sockaddr, sizeof(sockaddr))

    # Lee Sin
    mov rax, SYS_listen
    mov rdi, socket
    mov rsi, 5 # Backlog
    syscall ## listen(socket, 5)


# --- ACCEPT LOOP AS PARENT ---
accept_loop:
    # Accept a connection
    mov rax, SYS_accept
    mov rdi, socket
    xor rsi, rsi # NULL sockaddr
    xor rdx, rdx # NULL socklen
    # sockaddr and socklen are the info of the client (we don't need them)
    syscall ## accept(socket, NULL, NULL)
    mov client, rax # Save client socket fd

    # Fork process to handle client
    mov rax, SYS_fork
    syscall ## fork()
    cmp rax, 0 # Check if child process
    je handle_client ## If child, handle client

    # Close client socket in parent
    mov rax, SYS_close
    mov rdi, client
    syscall ## close(client_socket)
    jmp accept_loop ## Back to accept loop


# --- CLIENT HANDLING FROM CHILD ---
handle_client:
    # Read request from client
    mov rax, SYS_read
    mov rdi, client
    lea rsi, buffer_recv
    mov rdx, 1024 # Number of bytes to read
    syscall ## read(client_socket, buffer, 1024)
    mov r15, rax # Number of bytes read from client

    # Print the request to server console (stdout)
    mov rax, SYS_write
    mov rdi, 1 # stdout
    lea rsi, buffer_recv
    mov rdx, r15 # Number of bytes read from client
    syscall ## write(1, buffer, bytes_read)
    
    # Add spacing for readability
    mov rax, SYS_write
    mov rdi, 1 # stdout
    lea rsi, space
    mov rdx, 2
    syscall ## write(1, "\n\n", 2)

    # Parse the request to get method and path
    call parse_request

    # Handle based on method
    jmp handle_method


# --- PARSE THE REQUEST ---
parse_request:
    lea rsi, buffer_recv
    lea rdi, method
    mov rcx, 0

copy_method:
    mov al, byte ptr [rsi + rcx]
    cmp al, ' '
    je method_done
    mov byte ptr [rdi + rcx], al
    inc rcx
    jmp copy_method

method_done:
    mov byte ptr [rdi + rcx], 0 # Null-terminate method string
    lea rsi, [buffer_recv + rcx + 2] # Move past space and '/'
    lea rdi, path
    mov rcx, 0

copy_path:
    mov al, byte ptr [rsi + rcx]
    cmp al, ' '
    je path_done
    mov byte ptr [rdi + rcx], al
    inc rcx
    jmp copy_path

path_done:
    mov byte ptr [rdi + rcx], 0 # Null-terminate path string
    ret


# --- ROUTE BASED ON METHOD ---
handle_method:
    # If "GET"
    lea rsi, method
    lea rdi, method_get
    call strcmp
    cmp rax, 0
    je handle_get

    # Else if "POST"
    lea rsi, method
    lea rdi, method_post
    call strcmp
    cmp rax, 0
    je handle_post

    # Else if "PUT"
    lea rsi, method
    lea rdi, method_put
    call strcmp
    cmp rax, 0
    je handle_put

    # Else if "DELETE"
    lea rsi, method
    lea rdi, method_delete
    call strcmp
    cmp rax, 0
    je handle_delete

    # Else, method not supported
    jmp method_not_supported

# --- PARSE REQUEST BODY ---
read_body:
    # Body starts after double CRLF (0x0D 0x0A 0x0D 0x0A)
    lea rsi, buffer_recv
    mov rcx, 0
    mov rdx, r15 # Total bytes read
    mov rbx, 0 # Body start index
find_body:
    cmp rcx, rdx
    jge body_not_found
    mov al, byte ptr [rsi + rcx]
    cmp al, 0x0D # CR
    jne not_crlfcrlf
    mov al, byte ptr [rsi + rcx + 1]
    cmp al, 0x0A # LF
    jne not_crlfcrlf
    mov al, byte ptr [rsi + rcx + 2]
    cmp al, 0x0D # CR
    jne not_crlfcrlf
    mov al, byte ptr [rsi + rcx + 3]
    cmp al, 0x0A # LF
    jne not_crlfcrlf
    add rcx, 4
    mov rbx, rcx # Body starts here
    jmp body_found
not_crlfcrlf: # Not CRLFCRLF, continue searching
    inc rcx
    jmp find_body
body_found:
    lea rbx, [buffer_recv + rbx] # Body start address
    # Calculate body length
    lea rax, [buffer_recv + r15]
    sub rax, rbx
    mov r15, rax # Body length in r15

    xor rax, rax # Success
    ret
body_not_found:
    mov rax, -1 # Failure
    ret

# --- HANDLE GET REQUEST ---
handle_get:
    # Open file to read
    mov rax, SYS_open
    lea rdi, path
    xor rsi, rsi # O_RDONLY
    xor rdx, rdx
    syscall ## open(full_path, O_RDONLY)
    cmp rax, 0
    jl file_not_found
    mov r14, rax # Save file descriptor

    # Check if file is HTML
    lea rsi, path
    call is_html
    cmp rax, 1
    je send_html_header

    # Otherwise, send download header
    mov rax, SYS_write
    mov rdi, client
    lea rsi, http_header_download
    mov rdx, http_header_download_len
    syscall ## write(client, http_header_download, http_header_download_len)
    jmp send_file

send_html_header:
    mov rax, SYS_write
    mov rdi, client
    lea rsi, http_header_html
    mov rdx, http_header_html_len
    syscall ## write(client, http_header_html, http_header_html_len)
    
send_file:
    # Read file to buffer
    mov rax, SYS_read
    mov rdi, r14
    lea rsi, buffer_send
    mov rdx, 1024
    syscall ## read(file_fd, buffer_send, 1024)
    mov r15, rax
    
    # Write file content
    mov rax, SYS_write
    mov rdi, client
    lea rsi, buffer_send
    mov rdx, r15
    syscall ## write(client, buffer_send, bytes_read)
    
    # Close file
    mov rax, SYS_close
    mov rdi, r14
    syscall ## close(file_fd)
    
    # Close client connection
    jmp close_client


# --- CHECK IF PATH IS HTML FILE ---
is_html:
    # rsi = path
    mov rcx, 0
find_end_html:
    mov al, byte ptr [rsi + rcx]
    test al, al
    je check_html
    inc rcx
    jmp find_end_html
check_html:
    cmp rcx, 5
    jl not_html
    mov al, byte ptr [rsi + rcx - 5]
    cmp al, '.'
    jne not_html
    mov al, byte ptr [rsi + rcx - 4]
    cmp al, 'h'
    jne not_html
    mov al, byte ptr [rsi + rcx - 3]
    cmp al, 't'
    jne not_html
    mov al, byte ptr [rsi + rcx - 2]
    cmp al, 'm'
    jne not_html
    mov al, byte ptr [rsi + rcx - 1]
    cmp al, 'l'
    jne not_html
    mov rax, 1
    ret
not_html:
    xor rax, rax
    ret

    
# --- HANDLE POST REQUEST ---
handle_post:
    # Only support /submit path for POST
    lea rsi, path
    lea rdi, submit_path
    call strcmp
    cmp rax, 0
    jne method_not_supported

    # Open the file to append
    mov rax, SYS_open
    lea rdi, posts_path
    mov rsi, 1089 # O_WRONLY | O_CREAT | O_APPEND
    mov rdx, 0644 # Permissions
    syscall ## open(full_path, O_WRONLY | O_CREAT | O_APPEND, 0644)
    mov r14, rax # Save file descriptor

    # Get the body of the request
    call read_body
    cmp rax, 0
    jne bad_request

    # Write body to file
    mov rax, SYS_write
    mov rdi, r14
    mov rsi, rbx # Body start address
    mov rdx, r15 # Body length
    syscall ## write(file_fd, body, body_length)
    cmp rax, 0
    jl internal_server_error

    # Write timestamp using external C function
    mov rdi, r14 # File descriptor
    call write_timestamp
    cmp rax, 0
    jl internal_server_error

    # Respond with 200 OK
    mov rax, SYS_write
    mov rdi, client
    lea rsi, http_header_html
    mov rdx, http_header_html_len
    syscall ## write(client, http_header, http_header_len)

    # Close client connection
    jmp close_client


# --- HANDLE PUT REQUEST ---
handle_put:
    # Open file to write
    mov rax, SYS_open
    lea rdi, path
    mov rsi, 577 # O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644 # Permissions
    syscall ## open(full_path, O_WRONLY | O_CREAT | O_TRUNC, 0644)
    cmp rax, 0
    jl internal_server_error
    mov r14, rax # Save file descriptor

    # Get the body of the request
    call read_body
    cmp rax, 0
    jne bad_request
    
    # Write body to file
    mov rax, SYS_write
    mov rdi, r14
    mov rsi, rbx # Body start address
    mov rdx, r15 # Body length
    syscall ## write(file_fd, body, body_length)
    cmp rax, 0
    jl internal_server_error

    # Close file
    mov rax, SYS_close
    mov rdi, r14
    syscall ## close(file_fd)

    # Respond with 200 OK
    mov rax, SYS_write
    mov rdi, client
    lea rsi, http_header_html
    mov rdx, http_header_html_len
    syscall ## write(client, http_header, http_header_len)

    # Close client connection
    jmp close_client


# --- HANDLE DELETE REQUEST ---
handle_delete:
    # Let any delete request (yeah super insecure)
    # Open the file to delete (path is already parsed)
    mov rax, SYS_unlink
    lea rdi, path
    syscall ## unlink(path)
    cmp rax, 0
    jl internal_server_error

    # Respond with 200 OK
    mov rax, SYS_write
    mov rdi, client
    lea rsi, http_header_html
    mov rdx, http_header_html_len
    syscall ## write(client, http_header, http_header_len)

    # Close client connection
    jmp close_client


# --- RESPONSE HANDLERS ---
method_not_supported:
    # 405 Method Not Allowed
    mov rax, SYS_write
    mov rdi, client
    lea rsi, method_not_allowed_header
    mov rdx, method_not_allowed_header_len
    syscall ## write(client, method_not_allowed_header, method_not_allowed_header_len)
    jmp close_client

file_not_found:
    # 404 Not Found
    mov rax, SYS_write
    mov rdi, client
    lea rsi, file_not_found_header
    mov rdx, file_not_found_header_len
    syscall ## write(client, file_not_found_header, file_not_found_header_len)
    jmp close_client

internal_server_error:
    # 500 Internal Server Error
    mov rax, SYS_write
    mov rdi, client
    lea rsi, internal_server_error_header
    mov rdx, internal_server_error_header_len
    syscall ## write(client, internal_server_error_header, internal_server_error_header_len)
    jmp close_client

bad_request:
    # 400 Bad Request
    mov rax, SYS_write
    mov rdi, client
    lea rsi, bad_request_header
    mov rdx, bad_request_header_len
    syscall ## write(client, bad_request_header, bad_request_header_len)
    jmp close_client
    
    
# --- CLOSE CLIENT AND EXIT CHILD ---
close_client:
    # Close client socket
    mov rax, SYS_close
    mov rdi, client
    syscall ## close(client_socket)

    # Exit child process
    mov rax, SYS_exit
    xor rdi, rdi
    syscall ## exit(0)


# --- STRING COMPARE ---
strcmp:
    # Arguments: rdi = str1, rsi = str2
    # Return: rax = 0 if equal, <0 if str1 < str2, >0 if str1 > str2
    xor rax, rax

loop:
    mov al, byte ptr [rdi]
    mov bl, byte ptr [rsi]

    cmp al, bl
    jne diff

    test al, al
    je equal

    inc rdi
    inc rsi
    jmp loop

diff:
    sub al, bl
    movsx rax, al
    ret

equal:
    xor rax, rax
    ret
