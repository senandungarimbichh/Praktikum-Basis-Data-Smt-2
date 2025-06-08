-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 08 Jun 2025 pada 16.11
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `penjualan_novel`
--

DELIMITER $$
--
-- Prosedur
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `tambah_transaksi` (IN `p_id_pelanggan` INT, IN `p_id_buku` INT, IN `p_jumlah` INT)   BEGIN
    DECLARE v_harga DECIMAL(10,2);
    DECLARE v_stok INT;
    DECLARE v_total_harga DECIMAL(10,2);
    DECLARE v_judul VARCHAR(100);
    DECLARE v_nama_pelanggan VARCHAR(100);
    DECLARE v_msg_error VARCHAR(255);

    SELECT nama INTO v_nama_pelanggan
    FROM pelanggan
    WHERE id_pelanggan = p_id_pelanggan;

    IF v_nama_pelanggan IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Pelanggan tidak ditemukan';
    END IF;

    SELECT harga, stok, judul INTO v_harga, v_stok, v_judul
    FROM buku
    WHERE id_buku = p_id_buku;

    IF v_harga IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Buku tidak ditemukan';
    END IF;

    IF p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Jumlah harus lebih besar dari 0';
    END IF;

    IF v_stok < p_jumlah THEN
        SET v_msg_error = CONCAT('Error: Stok tidak mencukupi. Stok tersedia: ', v_stok, ', diminta: ', p_jumlah);
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_msg_error;
    END IF;

    SET v_total_harga = v_harga * p_jumlah;

    UPDATE buku
    SET stok = stok - p_jumlah
    WHERE id_buku = p_id_buku;

    INSERT INTO transaksi (id_pelanggan, id_buku, jumlah, total_harga, tanggal_transaksi)
    VALUES (p_id_pelanggan, p_id_buku, p_jumlah, v_total_harga, CURDATE());

    UPDATE pelanggan
    SET total_belanja = total_belanja + v_total_harga
    WHERE id_pelanggan = p_id_pelanggan;

    SELECT
        CONCAT('Transaksi berhasil! ', v_nama_pelanggan, ' membeli ', p_jumlah, ' buah "', v_judul, '" seharga Rp ', FORMAT(v_total_harga, 0)) AS pesan_sukses;
END$$

--
-- Fungsi
--
CREATE DEFINER=`root`@`localhost` FUNCTION `hitung_diskon` (`total_belanja` DECIMAL(10,2)) RETURNS DECIMAL(5,2) DETERMINISTIC BEGIN
    DECLARE diskon DECIMAL(5,2);
    IF total_belanja < 1000000 THEN
        SET diskon = 0.00;
    ELSEIF total_belanja >= 1000000 AND total_belanja < 5000000 THEN
        SET diskon = 0.05;
    ELSE
        SET diskon = 0.10;
    END IF;
    RETURN diskon;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `buku`
--

CREATE TABLE `buku` (
  `id_buku` int(11) NOT NULL,
  `judul` varchar(100) DEFAULT NULL,
  `penulis` varchar(100) DEFAULT NULL,
  `harga` decimal(10,2) DEFAULT NULL,
  `stok` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `buku`
--

INSERT INTO `buku` (`id_buku`, `judul`, `penulis`, `harga`, `stok`) VALUES
(1, 'Laut Bercerita', 'Leila S. Chudori', 95000.00, 20),
(2, 'Bumi', 'Tere Liye', 105000.00, 15),
(3, 'Negeri 5 Menara', 'Ahmad Fuadi', 98000.00, 25),
(4, 'Hujan', 'Tere Liye', 97000.00, 15),
(5, 'Perahu Kertas', 'Dewi Lestari', 115000.00, 10),
(6, 'Dilan 1990', 'Pidi Baiq', 88000.00, 30),
(7, 'Ayah', 'Andrea Hirata', 99000.00, 12),
(8, 'Orang-Orang Biasa', 'Andrea Hirata', 100000.00, 14),
(9, 'Ronggeng Dukuh Paruk', 'Ahmad Tohari', 92000.00, 9),
(10, 'Tentang Kamu', 'Tere Liye', 110000.00, 11);

-- --------------------------------------------------------

--
-- Struktur dari tabel `log_status_member`
--

CREATE TABLE `log_status_member` (
  `id_log` int(11) NOT NULL,
  `id_pelanggan` int(11) DEFAULT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `total_belanja_lama` decimal(10,2) DEFAULT NULL,
  `total_belanja_baru` decimal(10,2) DEFAULT NULL,
  `status_lama` varchar(20) DEFAULT NULL,
  `status_baru` varchar(20) DEFAULT NULL,
  `tanggal_update` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `pelanggan`
--

CREATE TABLE `pelanggan` (
  `id_pelanggan` int(11) NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `total_belanja` decimal(10,2) DEFAULT 0.00,
  `status_member` enum('REGULER','GOLD','PLATINUM') DEFAULT 'REGULER'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `pelanggan`
--

INSERT INTO `pelanggan` (`id_pelanggan`, `nama`, `total_belanja`, `status_member`) VALUES
(1, 'Nabila Azzahra', 1500000.00, 'GOLD'),
(2, 'Fahmi Rizky Pratama', 7000000.00, 'PLATINUM'),
(3, 'Salsabila Nuraini', 500000.00, 'REGULER'),
(4, 'Daffa Aditya Nugraha', 0.00, 'REGULER'),
(5, 'Rizky Amelia Putri', 0.00, 'REGULER'),
(6, 'Galang Pradipta', 0.00, 'REGULER'),
(7, 'Aulia Rahmawati', 0.00, 'REGULER'),
(8, 'Kevin Ramadhan', 0.00, 'REGULER');

--
-- Trigger `pelanggan`
--
DELIMITER $$
CREATE TRIGGER `update_status_member` BEFORE UPDATE ON `pelanggan` FOR EACH ROW BEGIN
    IF NEW.total_belanja != OLD.total_belanja THEN
        IF NEW.total_belanja >= 5000000 THEN
            SET NEW.status_member = 'PLATINUM';
        ELSEIF NEW.total_belanja >= 1000000 THEN
            SET NEW.status_member = 'GOLD';
        ELSE
            SET NEW.status_member = 'REGULER';
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktur dari tabel `transaksi`
--

CREATE TABLE `transaksi` (
  `id_transaksi` int(11) NOT NULL,
  `id_pelanggan` int(11) DEFAULT NULL,
  `id_buku` int(11) DEFAULT NULL,
  `jumlah` int(11) DEFAULT NULL,
  `total_harga` decimal(10,2) DEFAULT NULL,
  `tanggal_transaksi` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `transaksi`
--

INSERT INTO `transaksi` (`id_transaksi`, `id_pelanggan`, `id_buku`, `jumlah`, `total_harga`, `tanggal_transaksi`) VALUES
(1, 1, 2, 3, 315000.00, '2025-06-08');

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `buku`
--
ALTER TABLE `buku`
  ADD PRIMARY KEY (`id_buku`);

--
-- Indeks untuk tabel `log_status_member`
--
ALTER TABLE `log_status_member`
  ADD PRIMARY KEY (`id_log`);

--
-- Indeks untuk tabel `pelanggan`
--
ALTER TABLE `pelanggan`
  ADD PRIMARY KEY (`id_pelanggan`);

--
-- Indeks untuk tabel `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`id_transaksi`),
  ADD KEY `id_pelanggan` (`id_pelanggan`),
  ADD KEY `id_buku` (`id_buku`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `buku`
--
ALTER TABLE `buku`
  MODIFY `id_buku` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT untuk tabel `log_status_member`
--
ALTER TABLE `log_status_member`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT untuk tabel `pelanggan`
--
ALTER TABLE `pelanggan`
  MODIFY `id_pelanggan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT untuk tabel `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id_transaksi` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `transaksi`
--
ALTER TABLE `transaksi`
  ADD CONSTRAINT `transaksi_ibfk_1` FOREIGN KEY (`id_pelanggan`) REFERENCES `pelanggan` (`id_pelanggan`),
  ADD CONSTRAINT `transaksi_ibfk_2` FOREIGN KEY (`id_buku`) REFERENCES `buku` (`id_buku`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
