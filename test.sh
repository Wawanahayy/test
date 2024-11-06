#!/bin/bash

# Fungsi untuk mengambil bagian-bagian dari URL proxy
function parse_proxy() {
    # Format input: http://username:password@ip:port
    proxy_url=$1

    # Menghapus "http://" dari awal URL jika ada
    proxy_url=${proxy_url//http:\/\//}

    # Menggunakan pemisah "@" untuk membagi bagian username:password dan ip:port
    user_pass=${proxy_url%%@*}
    ip_port=${proxy_url#*@}

    # Memisahkan username dan password
    username=${user_pass%%:*}
    password=${user_pass#*:}

    # Memisahkan ip dan port
    ip=${ip_port%%:*}
    port=${ip_port#*:}

    # Menampilkan hasil pemisahan
    echo "Proxy Details:"
    echo "Username: $username"
    echo "Password: $password"
    echo "IP: $ip"
    echo "Port: $port"
}

# Menanyakan pengguna untuk memasukkan proxy HTTP dalam format: http://username:password@ip:port
read -p "Masukkan proxy HTTP (contoh: http://username:password@ip:port): " proxy

# Panggil fungsi parse_proxy untuk memisahkan bagian-bagian dari URL proxy
parse_proxy "$proxy"

# Menetapkan proxy untuk digunakan di curl atau wget
export http_proxy="http://$username:$password@$ip:$port"
export https_proxy="http://$username:$password@$ip:$port"

# Melakukan update sistem menggunakan proxy yang disetel
echo "Mengupdate sistem menggunakan proxy..."
sudo apt update -y && sudo apt upgrade -y

# Melakukan instalasi Docker jika belum ada
if ! command -v docker &> /dev/null; then
    echo "Docker tidak ditemukan, sedang menginstal Docker..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo "Docker sudah terinstal, melanjutkan ke langkah berikutnya..."
fi

# Melakukan instalasi Docker Compose
echo "Menginstal Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Membuat folder untuk mengekstrak file
mkdir -p target/release

# Mengunduh dan mengekstrak BlockMesh CLI
echo "Mengunduh BlockMesh CLI..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.340/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

# Memastikan blockmesh-cli telah diekstrak dengan benar
if [[ ! -f target/release/blockmesh-cli ]]; then
    echo "Error: Tidak ditemukan file blockmesh-cli di target/release. Keluar..."
    exit 1
fi

# Meminta email dan password untuk login BlockMesh
read -p "Masukkan email BlockMesh Anda: " email
read -s -p "Masukkan password BlockMesh Anda: " password
echo

# Menjalankan BlockMesh dalam Docker
echo "Menjalankan BlockMesh dalam Docker..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

