.intel_syntax noprefix

# -----------------------------------------------------------
.section .data

# -- System call numbers --
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
SYS_rt_sigaction = 13


# -- Signal constants --
SIGINT = 2
.align 8
sigaction:
    .quad signal_handler
    .quad 0
    .quad 0, 0
    .zero 128


# -- Socket constants --
AF_INET=2
SOCK_STREAM=1

# Sockaddr struct
sockaddr:
    .word AF_INET
    .byte 0x1e, 0x61 # Port (7777)
    .byte 0, 0, 0, 0 # IP
    .zero 8 # Padding to make it 16 bytes


# -- Headers --
http_header: .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
http_header_len = . - http_header

method_not_allowed_header: .asciz "HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/html\r\n\r\n"
method_not_allowed_header_len = . - method_not_allowed_header

file_not_found_header: .asciz "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\n\r\n"
file_not_found_header_len = . - file_not_found_header

internal_server_error_header: .asciz "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/html\r\n\r\n"
internal_server_error_header_len = . - internal_server_error_header


# -----------------------------------------------------------
.section .bss

socket: .quad 0 # Host socket file descriptor
client: .quad 0 # Client socket file descriptor
buffer_recv: .space 1024 # Buffer for reading requests
buffer_send: .space 1024 # Buffer for sending responses
request_path: .space 256 # Buffer for storing the requested path
full_path: .space 260 # Buffer for storing full file path


# -----------------------------------------------------------
.section .text

# -- Signal handler for graceful shutdown --
signal_handler:
    # Close the server socket
    mov rax, SYS_close
    mov rdi, socket
    syscall ## close(socket)

    # Exit the process
    mov rax, SYS_exit
    xor rdi, rdi
    syscall ## exit(0)

# -- Create server socket and listen for connections --
.global _start
_start:
    # Set up signal handler for SIGINT
    mov rax, SYS_rt_sigaction
    mov rdi, SIGINT
    lea rsi, sigaction
    xor rdx, rdx
    syscall ## rt_sigaction(SIGINT, &sigaction, NULL, 8)

    # Create socket
    mov rax, SYS_socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall ## socket(AF_INET, SOCK_STREAM, 0)
    mov socket, rax # Save socket fd
    
    # Bind socket
    mov rax, SYS_bind
    mov rdi, socket # Socket fd
    lea rsi, sockaddr # &sockaddr
    mov rdx, 16 # sizeof(sockaddr)
    syscall ## bind(socket, &sockaddr, sizeof(sockaddr))
    
    # Lee Sin
    mov rax, SYS_listen
    mov rdi, socket # Socket fd
    mov rsi, 5 # Backlog
    syscall ## listen(socket, 5)

    
# -- Loop to accept and handle connections --
accept_loop:
    # Accept connection
    mov rax, SYS_accept
    mov rdi, socket # Socket fd
    xor rsi, rsi # NULL sockaddr
    xor rdx, rdx # NULL socklen
    # sockaddr and socklen are the info of the client (we don't need them)
    syscall ## accept(socket, NULL, NULL)
    mov client, rax # Save client socket fd
    
    # Fork process to handle client
    mov rax, SYS_fork
    syscall ## fork()
    cmp rax, 0
    je handle_client
    # Child process handles the client
    
    # Close client socket in parent
    mov rax, SYS_close
    mov rdi, client # Client socket fd
    syscall ## close(client_socket)
    jmp accept_loop

    
# -- Handle client request in child process --
handle_client:
    # Read request from client
    mov rax, SYS_read
    mov rdi, client # Client socket fd
    lea rsi, buffer_recv # Buffer to read into
    mov rdx, 1024 # Number of bytes to read
    syscall ## read(client_socket, buffer, 1024)
    mov r15, rax # Save number of bytes read
    
    # Print the request to server console (stdout)
    mov rax, SYS_write
    mov rdi, 1 # stdout
    lea rsi, buffer_recv
    mov rdx, r15 # Number of bytes read from client
    syscall ## write(1, buffer, bytes_read)

    
# -- Parse HTTP method --
parse_method:
    lea rsi, buffer_recv
    mov eax, [rsi] # Load first 4 bytes

    cmp eax, 0x20544547 # "GET "
    je handle_get

    cmp eax, 0x54534F50 # "POST"
    je handle_post
    
    cmp eax, 0x20545550 # "PUT "
    je handle_put
    
    cmp eax, 0x454C4544 # "DELE"
    jne method_not_supported
    mov ebx, [rsi+4]
    cmp ebx, 0x20204554 # "TE  "
    je handle_delete

    
# -- Parse request path --
parse_path: # rsi should point to buffer_recv before calling
    mov rcx, 4 # Start after method and space
    lea rdi, request_path

parse_path_loop:
    mov al, [rsi + rcx]
    cmp al, ' ' # End of path
    je path_done
    mov [rdi], al
    inc rdi
    inc rcx
    jmp parse_path_loop

path_done:
    mov BYTE PTR [rdi], 0 # Null-terminate

    # Build full path: "res/" + request_path (skip leading '/')
    lea rsi, full_path
    mov BYTE PTR [rsi+0], 'r'
    mov BYTE PTR [rsi+1], 'e'
    mov BYTE PTR [rsi+2], 's'
    mov BYTE PTR [rsi+3], '/'
    lea rdi, request_path
    mov rcx, 0

copy_path:
    mov al, [rdi+rcx+1] # Skip leading '/'
    mov [rsi+4+rcx], al
    cmp al, 0
    je path_built
    inc rcx
    jmp copy_path

path_built:
    ret

    
# -- Header response handler --
method_not_supported:
    # Send 405 Method Not Allowed
    mov rax, SYS_write
    mov rdi, client
    lea rsi, method_not_allowed_header
    mov rdx, method_not_allowed_header_len
    syscall ## write(client, method_not_allowed_header, method_not_allowed_header_len)
    jmp close_client

file_not_found:
    # Send 404 Not Found
    mov rax, SYS_write
    mov rdi, client
    lea rsi, file_not_found_header
    mov rdx, file_not_found_header_len
    syscall ## write(client, file_not_found_header, file_not_found_header_len)
    jmp close_client
    
internal_server_error:
    # Send 500 Internal Server Error
    mov rax, SYS_write
    mov rdi, client
    lea rsi, internal_server_error_header
    mov rdx, internal_server_error_header_len
    syscall ## write(client, internal_server_error_header, internal_server_error_header_len)
    jmp close_client
    
    
# --- MEHTHOD HANDLERS ---
# -- GET --
handle_get:
    lea rsi, buffer_recv
    call parse_path

    # Open file for reading
    mov rax, SYS_open
    lea rdi, full_path
    xor rsi, rsi # O_RDONLY
    xor rdx, rdx
    syscall ## open(full_path, O_RDONLY)
    cmp rax, 0
    jl file_not_found
    mov r14, rax

    # Read file
    mov rax, SYS_read
    mov rdi, r14
    lea rsi, buffer_send
    mov rdx, 1024
    syscall ## read(file_fd, buffer_send, 1024)
    mov r15, rax

    # Write HTTP header
    mov rax, SYS_write
    mov rdi, client
    lea rsi, http_header
    mov rdx, http_header_len
    syscall ## write(client, http_header, http_header_len)

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
    jmp close_client

    
# -- POST --
handle_post:
    lea rsi, buffer_recv
    call parse_path

# -- PUT --
handle_put:
    lea rsi, buffer_recv
    call parse_path
    # Continue with PUT logic
    
    jmp close_client
    
# -- DELETE --
handle_delete:
    lea rsi, buffer_recv
    call parse_path
    # Continue with DELETE logic
    
    jmp close_client

# -- Finish client request --    
close_client:
    # Close client socket
    mov rax, SYS_close
    mov rdi, client
    syscall ## close(client_socket)
    
    # Exit child process
    mov rax, SYS_exit
    xor rdi, rdi
    syscall ## exit(0)
