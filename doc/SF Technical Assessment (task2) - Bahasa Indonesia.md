# Asesmen Teknis Salesforce v3.2

# Penafian

- Tugas ini hanya digunakan untuk keperluan resmi dan tidak boleh direproduksi untuk kepentingan pribadi atau dibagikan kepada pihak lain.

- Hasil yang Anda kirimkan harus sepenuhnya merupakan karya Anda sendiri dan diselesaikan tanpa bantuan eksternal dari individu lain. Segala bentuk plagiarisme akan menyebabkan tugas Anda dibatalkan dan lamaran Anda tidak lagi dipertimbangkan.

# Prasyarat

1. Daftar atau masuk ke akun Salesforce Trailblazer Anda.

2. Buat akun developer edition Trailhead Playground yang **baru** untuk mengimplementasikan solusi Anda melalui kode.

3. Anda dapat menggunakan IDE Visual Studio Code dengan ekstensi Apex PMD untuk mengerjakan tugas ini.

# Tugas-2\. Asesmen Berbasis Skenario

Anda ditugaskan untuk merancang arsitektur solusi Salesforce bagi sebuah instansi pemerintah yang menyediakan layanan terkait pertanyaan dan umpan balik warga.

# Peran dan Tanggung Jawab

- **Admin Cabang** \- Perlu memantau seluruh permintaan yang masuk melalui berbagai saluran kontak warga dalam divisinya. Mereka tidak terlibat langsung dalam penyelesaian kasus, tetapi membutuhkan gambaran menyeluruh untuk keperluan manajemen dan pengawasan.

- **Supervisor** \- Mengawasi para agen dan memastikan mereka menangani kasus pertanyaan maupun umpan balik secara efektif, terlepas dari saluran komunikasi yang digunakan.

- **Agen \-** Berinteraksi langsung dengan warga, menangani pertanyaan sehari-hari, serta memproses umpan balik yang diterima melalui saluran kontak warga mana pun.

# Manajemen Kasus

**Kasus Pertanyaan**: Mencakup penanganan pertanyaan, kekhawatiran, atau permintaan informasi dari warga mengenai layanan instansi.

Proses kasus pertanyaan secara garis besar:

1. **Inisiasi** \- Warga mengajukan pertanyaan melalui salah satu saluran yang tersedia.
2. **Verifikasi** \- Agen memverifikasi data warga, terutama menggunakan nomor telepon atau alamat email warga, dengan mencocokkannya terhadap sistem manajemen data induk eksternal.
3. **Pencatatan Kasus** \- Informasi pertanyaan secara terperinci beserta dokumen pendukung, misalnya foto, dicatat dalam sistem.
4. **Penugasan Kasus** \- Sistem menugaskan kasus kepada agen berdasarkan kondisi seperti keahlian, bahasa, beban kerja, dan ketersediaan.
5. **Penyelesaian** \- Agen menangani pertanyaan dan, untuk kasus yang kompleks, dapat melibatkan Supervisor. Untuk kasus yang telah memiliki solusi, agen memberikan solusi yang relevan. Jika belum ada, agen menyusun dan mendokumentasikan solusi baru.
6. **Tindak Lanjut** \- Tindak lanjut secara berkala dengan warga dilakukan hingga kasus terselesaikan sepenuhnya.
7. **Penutupan** \- Setelah masalah terselesaikan, kasus ditutup dengan konfirmasi dari warga.

**Kasus Umpan Balik**: Mencakup pemrosesan umpan balik, keluhan, atau saran warga mengenai layanan instansi.

Proses kasus umpan balik secara garis besar:

1. **Penerimaan** \- Umpan balik diterima melalui saluran yang telah ditentukan.
2. **Pencatatan** \- Rincian umpan balik dicatat dalam sistem, termasuk layanan atau produk tertentu yang berkaitan dengan umpan balik tersebut.
3. **Analisis** \- Agen menganalisis umpan balik untuk memahami tingkat kepuasan warga dan area yang perlu ditingkatkan.
4. **Respons** \- Jika diperlukan, agen memberikan respons kepada warga.
5. **Pelaporan** \- Umpan balik dikompilasi untuk tinjauan internal sehingga mendukung perbaikan dan perencanaan strategis.
6. **Evaluasi** \- Supervisor meninjau proses dan hasil penanganan umpan balik untuk menilai kinerja agen serta tingkat kepuasan warga.

# Saluran Kontak

- Warga dapat mengajukan kasus secara langsung melalui situs web instansi.
- Warga dapat menghubungi instansi melalui telepon untuk melaporkan masalah atau mengajukan pertanyaan.
- Warga dapat memperoleh bantuan secara waktu nyata melalui situs web atau aplikasi seluler instansi.
- Warga dapat mengirimkan pertanyaan atau umpan balik melalui email.

# Persyaratan Tingkat Tinggi

- Sistem harus mampu terintegrasi dengan sistem manajemen data induk eksternal untuk verifikasi warga.
- Sistem harus fleksibel agar dapat beradaptasi terhadap perubahan.
- Penanganan data mencakup migrasi data selama 10 tahun yang berjumlah 6 juta rekaman dan file berukuran 100 GB.
- Sistem harus mampu menangani 5.000 kasus baru dan unggahan file sebesar 100 MB setiap hari.
- Terapkan Single Sign-On (SSO) menggunakan Microsoft Active Directory yang sudah ada.
- Sistem harus memungkinkan Admin Cabang mengevaluasi kinerja setiap agen berdasarkan efektivitas mereka dalam menangani kasus melalui berbagai saluran kontak.

Tantangan Anda adalah merancang solusi yang memenuhi persyaratan bisnis di atas. Solusi desain arsitektur tersebut akan dibahas selama wawancara. Harap bersiap untuk mempresentasikan dan memberikan justifikasi atas desain Anda.

Solusi harus mencakup secara menyeluruh aspek-aspek berikut, antara lain:

- Lisensi, edisi, dan fitur Salesforce, serta alat pihak ketiga yang diperlukan
- Diagram lanskap sistem
- Proses bisnis, misalnya user story
- Pertimbangan integrasi
- Pertimbangan model data, misalnya Entity-Relationship Diagram (ERD), desain berbagi data, dan keamanan
- Rencana migrasi data

| _Anda dapat membuat asumsi yang wajar untuk bagian ini. Jangan lupa menyatakan asumsi Anda dengan jelas._ |
| :-------------------------------------------------------------------------------------------------------: |
