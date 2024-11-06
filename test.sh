#!/bin/bash

# Path penyimpanan script
SCRIPT_PATH="$HOME/BlockMesh.sh"

# Periksa apakah script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Script ini harus dijalankan dengan hak akses root."
    echo "Coba gunakan perintah 'sudo -i' untuk berpindah ke pengguna root, lalu jalankan ulang script ini."
    exit 1
fi

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        echo "Script ini dibuat oleh komunitas Dadu Besar, Twitter: @ferdie_jhovie, gratis dan open-source. Jangan percaya yang berbayar."
        echo "Jika ada masalah, hubungi Twitter. Hanya ada satu akun."
        echo "================================================================"
        echo "Untuk keluar dari script, tekan ctrl + C."
        echo "Pilih operasi yang ingin dijalankan:"
        echo "1. Deploy node"
        echo "2. Lihat log"
        echo "3. Keluar"

        read -p "Masukkan pilihan (1-3): " option

        case $option in
            1)
                deploy_node
                ;;
            2)
                view_logs
                ;;
            3)
                echo "Keluar dari script."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi."
                read -p "Tekan tombol apapun untuk melanjutkan..."
                ;;
        esac
    done
}

# Deploy node
function deploy_node() {
    echo "Memperbarui sistem..."
    sudo apt update -y && sudo apt upgrade -y

    # Bersihkan file lama
    rm -rf blockmesh-cli.tar.gz target

    # Cek dan hapus container yang ada
    if [ "$(docker ps -aq -f name=blockmesh-cli-container)" ]; then
        echo "Container blockmesh-cli-container ditemukan, menghentikan dan menghapusnya..."
        docker stop blockmesh-cli-container
        docker rm blockmesh-cli-container
        echo "Container dihentikan dan dihapus."
    fi

    # Instal Docker jika belum terpasang
    if ! command -v docker &> /dev/null; then
        echo "Menginstal Docker..."
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
    else
        echo "Docker sudah terpasang, melewati langkah instalasi..."
    fi

    # Instal Docker Compose
    echo "Menginstal Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Buat direktori tujuan untuk ekstraksi
    mkdir -p target/release

    # Download dan ekstrak versi terbaru BlockMesh CLI
    echo "Mendownload dan mengekstrak BlockMesh CLI..."
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.340/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

    # Verifikasi hasil ekstraksi
    if [[ ! -f target/release/blockmesh-cli ]]; then
        echo "Error: File blockmesh-cli tidak ditemukan di target/release. Keluar..."
        exit 1
    fi

    # Minta email dan password
    read -p "Masukkan email BlockMesh Anda: " email
    read -s -p "Masukkan password BlockMesh Anda: " password
    echo

    # Jalankan container Docker untuk BlockMesh CLI
    echo "Membuat container Docker untuk BlockMesh CLI..."
    docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

    read -p "Tekan tombol apapun untuk kembali ke menu utama..."
}

# Lihat log
function view_logs() {
    # Tampilkan log terakhir dari container blockmesh-cli-container
    echo "Menampilkan log dari container blockmesh-cli-container:"
    docker logs --tail 100 blockmesh-cli-container

    # Cek apakah container ada
    if [ $? -ne 0 ]; then
        echo "Error: Container blockmesh-cli-container tidak ditemukan."
    fi

    read -p "Tekan tombol apapun untuk kembali ke menu utama..."
}

# Jalankan menu utama
main_menu
