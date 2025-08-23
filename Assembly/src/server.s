.intel_syntax noprefix

# -----------------------------------------------------------

.section .data
# System call numbers
SYS_socket = 41
SYS_bind = 49
SYS_listen = 50
SYS_accept = 43

SYS_read = 0
SYS_write = 1
SYS_open = 2
SYS_close = 3
SYS_exit = 60

# Socket constants
AF_INET=2
SOCK_STREAM=1

# Sockaddr struct
sockaddr:
    .word AF_INET
    .byte 0x1b, 0x39 # Port (6969)
    .byte 0, 0, 0, 0 # IP
    .quad 0
    
# Web constants
path: .asciz "res/index.html"
http_header: .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n"
http_header_len = . - http_header

# -----------------------------------------------------------

.section .bss
socket: .quad 0 # Host socket file descriptor
client: .quad 0 # Client socket file descriptor
buffer_recv: .space 1024 # Buffer for reading requests
buffer_send: .space 1024 # Buffer for sending responses

# -----------------------------------------------------------

.section .text
.global _start
_start:
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

accept_loop:
    # Accept connection
    mov rax, SYS_accept
    mov rdi, socket # Socket fd
    xor rsi, rsi # NULL sockaddr
    xor rdx, rdx # NULL socklen
    # sockaddr and socklen are the info of the client (we don't need them)
    syscall ## accept(socket, NULL, NULL)
    mov client, rax # Save client socket fd
    
    # Read request from client
    mov rax, SYS_read
    mov rdi, client # Client socket fd
    lea rsi, buffer_recv # Buffer to read into
    mov rdx, 1024 # Number of bytes to read
    syscall ## read(client_socket, buffer, 1024)
    
    # Open requested file
    # Assuming the request is for "res/index.html"
    mov rax, SYS_open
    lea rdi, path # Path to the file
    xor rsi, rsi # O_RDONLY
    xor rdx, rdx # No flags
    syscall ## open("res/index.html", O_RDONLY)
    mov r14, rax # Save file descriptor in r14
    
    # Read file content
    mov rax, SYS_read
    mov rdi, r14 # File descriptor
    lea rsi, buffer_send # Buffer to read into
    mov rdx, 1024 # Number of bytes to read
    syscall ## read(file_descriptor, buffer_send, 1024)
    mov r15, rax # Save number of bytes read in r15
    
    # Write HTTP header
    mov rax, SYS_write
    mov rdi, client # Client socket fd
    lea rsi, http_header # Buffer with HTTP header
    mov rdx, http_header_len # Length of HTTP header
    syscall ## write(client_socket, http_header, http_header_len)
    
    # Write page content
    mov rax, SYS_write
    mov rdi, client # Client socket fd
    lea rsi, buffer_send # Buffer with file content
    mov rdx, r15 # Number of bytes read from file
    syscall ## write(client_socket, buffer_send, bytes_read)

    # Close file descriptor
    mov rax, SYS_close
    mov rdi, r14 # File descriptor
    syscall ## close(file_descriptor)
    
    # Close client socket
    mov rax, SYS_close
    mov rdi, client # Client socket fd
    syscall ## close(client_socket)
    
    jmp accept_loop
    
    # Exit the program
    mov rax, SYS_exit
    xor rdi, rdi # Exit code 0
    syscall ## exit(0)
