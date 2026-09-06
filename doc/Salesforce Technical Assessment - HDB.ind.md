# Asesmen Teknis Salesforce v3.2

# Pernyataan Ketentuan

- Tugas ini hanya digunakan untuk keperluan resmi dan tidak boleh diperbanyak untuk kepentingan pribadi atau dibagikan kepada orang lain.

- Hasil yang Anda serahkan harus sepenuhnya merupakan pekerjaan Anda sendiri dan diselesaikan tanpa bantuan eksternal dari orang lain. Segala bentuk plagiarisme akan mengakibatkan tugas Anda dibatalkan, dan lamaran Anda tidak akan dipertimbangkan lebih lanjut.

# Prasyarat

1. Daftar atau masuk ke akun Salesforce Trailblazer Anda.

2. Buat akun Trailhead Playground developer edition **baru** untuk mengimplementasikan solusi Anda melalui kode.

3. Anda dapat menggunakan IDE Visual Studio Code dengan ekstensi Apex PMD untuk mengerjakan tugas ini.

**1\. Asesmen Pemrograman**

# Latar Belakang

Instansi X menawarkan tiga opsi bantuan keuangan bagi individu berpenghasilan rendah:

- Opsi 1: SGD 500 per bulan selama 3 bulan
- Opsi 2: SGD 300 per bulan selama 6 bulan
- Opsi 3: SGD 200 per bulan selama 12 bulan

Individu dapat mengirimkan informasi mereka dan memilih opsi bantuan melalui Salesforce. Mereka juga diperbolehkan mengubah opsi bantuan yang dipilih setelah pengajuan awal.

# Tujuan

Tugas Anda adalah mengembangkan Salesforce Lightning Web Components (LWC) untuk mencatat nama depan, nama belakang, nomor telepon, kode pos, penghasilan bulanan, dan opsi bantuan pemohon, serta logika back-end melalui Apex untuk menangani pencairan bulanan.

# Kebutuhan Bisnis

**User Story 1**  
Sebagai Pemohon Bantuan, saya ingin mengajukan permohonan bantuan keuangan secara online agar saya dapat dipertimbangkan untuk menerima bantuan keuangan dari Instansi X.

Kriteria Penerimaan:

- Pemohon bantuan dapat mengirimkan formulir pengajuan online menggunakan Salesforce Experience Cloud Site.

- Gunakan LWC untuk antarmuka pengguna formulir pengajuan online.

- Formulir pengajuan online harus menyertakan field **wajib** untuk memberikan informasi pribadi dan menyatakan penghasilan bulanan pemohon sebagai berikut:

  - **Nama Depan Pemohon (Applicant First Name)**
  - **Nama Belakang Pemohon (Applicant Last Name)**
  - **Telepon (Phone)** - harus berupa nomor telepon Singapura yang valid dengan format: `65<space>6812<space>3456`. Format lain tidak boleh diterima.
  - **Kode Pos Alamat Surat (Mailing Postal Code)** - hanya boleh berupa angka 6 digit (misalnya 123456).
  - **Penghasilan Bulanan (Monthly Income)** - harus berupa angka yang menyatakan jumlah dalam SGD.
  - **Opsi Bantuan (Support Option)** - tiga opsi yang tersedia sebagaimana disebutkan pada bagian Latar Belakang.

- Saat diajukan, permohonan harus diproses untuk membuat **Contact** baru di Salesforce jika nomor telepon yang diberikan belum terkait dengan Contact yang sudah ada.

**User Story 2**  
Sebagai Administrator Bantuan, saya ingin record Grant Disbursed yang terkait dengan Contact dibuat setelah lolos pemeriksaan kelayakan agar saya dapat memantau alokasi dana untuk memastikan transparansi dan akuntabilitas.

Kriteria Penerimaan:

- Pemeriksaan kelayakan hanya boleh dinyatakan lolos jika **Penghasilan Bulanan** pemohon kurang dari SGD 1800.

- Record Grant Disbursed harus dibuat berdasarkan opsi bantuan yang dipilih\*:

  - **Opsi Satu: SGD 500 selama 3 bulan** - Jika dipilih, 3 record harus dibuat dengan mengisi setiap record Grant Disbursed berdasarkan pilihan picklist, dengan setiap record mewakili pencairan untuk satu bulan.
  - **Opsi Dua: SGD 300 selama 6 bulan** - Jika dipilih, 6 record harus dibuat dengan mengisi setiap record Grant Disbursed berdasarkan pilihan picklist, dengan setiap record mewakili pencairan untuk satu bulan.
  - **Opsi Tiga: SGD 200 selama 12 bulan** - Jika dipilih, 12 record harus dibuat dengan mengisi setiap record Grant Disbursed berdasarkan pilihan picklist, dengan setiap record mewakili pencairan untuk satu bulan.

- Setiap record “Grant Disbursed” harus menyertakan field kustom berikut:

  - **Pemohon Bantuan (Grant Applicant)** (Contact Lookup) - record Contact milik pemohon bantuan.
  - **Jumlah yang Akan Dicairkan (Amount to be disbursed)** (Currency) - nilai default mengikuti nilai pada opsi bantuan yang dipilih di atas.
  - **Apakah Bantuan Sudah Dicairkan? (Grant is disbursed?)** (Checkbox) - asumsikan bahwa setiap bantuan akan dicairkan pada Tanggal Pencairan.
  - **Tanggal Pencairan (Disbursed Date)** (Date) - tanggal pencairan adalah tanggal 1 setiap bulan, dengan bulan pencairan pertama merupakan bulan setelah tanggal pengajuan (misalnya, jika tanggal pengajuan = 29 Feb 2024 dan Opsi Bantuan Satu dipilih, Tanggal Pencairannya adalah 1 Mar 2024, 1 Apr 2024, dan 1 Mei 2024).

\*Di masa mendatang, Administrator Bantuan menginginkan fleksibilitas untuk menambahkan opsi lain dan/atau mengubah opsi yang sudah ada.

**User Story 3**  
Sebagai Pemohon Bantuan, saya ingin memperbarui permohonan bantuan keuangan saya melalui formulir pengajuan yang sama agar saya dapat memperoleh bantuan keuangan yang tepat dari Instansi X.

Kriteria Penerimaan:

- Setelah permohonan dikirim menggunakan nomor telepon yang sama dengan Contact yang sudah ada, informasi pada field berikut di Contact tersebut harus diperbarui sesuai data yang dikirim.
  - **Nama Depan Pemohon (Applicant First Name)**
  - **Nama Belakang Pemohon (Applicant Last Name)**
  - **Telepon (Phone)**
  - **Kode Pos Alamat Surat (Mailing Postal Code)**
  - **Penghasilan Bulanan (Monthly Income)**
  - **Opsi Bantuan (Support Option)**

- Jika pemohon ingin mengubah opsi bantuan di tengah periode opsi yang sedang berjalan, aturan berikut berlaku:
  - Pemohon dapat mengubah opsi bantuan selama total jumlah yang sudah dicairkan lebih kecil daripada total jumlah pada opsi baru. Saat opsi bantuan diubah, hitung ulang sisa dana berdasarkan opsi baru. Sisa jumlah tersebut harus dibagikan secara merata selama sisa bulan pada opsi baru. Misalnya, jika pemohon berpindah dari Opsi Satu ke Opsi Dua setelah menerima bantuan selama dua bulan, sisa 800 akan dibagi selama empat bulan berikutnya, sehingga menghasilkan SGD 200 per bulan.

  - Pemohon tidak dapat mengubah opsi bantuan jika total jumlah yang sudah dicairkan lebih besar daripada total jumlah pada opsi baru.  
    Misalnya, jika seseorang mencoba berpindah dari Opsi Tiga ke Opsi Satu setelah sepuluh bulan, mereka tidak dapat melakukan perubahan karena total jumlah yang diterima adalah SGD 1800, yang lebih besar daripada total bantuan Opsi Satu (SGD 1500). Pilihan yang tidak valid ini perlu ditangani dengan tepat.

**User Story 4**  
Sebagai Administrator Bantuan, saya ingin memiliki fleksibilitas untuk membuat record permohonan secara manual atau mengunggah banyak permohonan sekaligus ke Salesforce agar saya dapat memasukkan banyak permohonan bantuan ke Salesforce dengan cepat.

Kriteria Penerimaan:

- Anda bebas menggunakan alat unggah data Salesforce apa pun.

- Pengunggahan [contoh CSV](https://docs.google.com/spreadsheets/d/1zAL85lSt5kj1hEcpt0bW7DHK798Noru6p9RwmLF_Qno/edit#gid=0) tidak boleh melewati aturan validasi apa pun.

- Setelah semua record diproses, record Contact dan record Grant Disbursed harus dibuat sebagaimana mestinya tanpa kesalahan.

- Jika ditemukan nomor telepon yang cocok, perbarui record Contact yang sudah ada dengan informasi terbaru.

# Kriteria Evaluasi

Experience Cloud:

- Menunjukkan pemahaman Anda mengenai fungsi Experience Cloud, seperti membuat dan mengelola situs yang dapat diakses publik serta menyediakan fungsi Salesforce kepada pengguna eksternal.

Pengembangan LWC:

- Mampu mengembangkan komponen LWC untuk antarmuka pengguna dan memverifikasi integritas data.

- Menunjukkan keterampilan dalam penanganan exception (misalnya negara penagihan yang belum diisi, format telepon yang tidak valid, dan sebagainya). Anda harus mencegah pengiriman formulir online dan menampilkan pesan kesalahan yang mudah dipahami pengguna. Administrator Salesforce harus memiliki cara yang mudah untuk memperbarui dan mengelola pesan kesalahan tersebut.

- Mematuhi praktik terbaik LWC.

Pengembangan Apex:

- Menunjukkan ketepatan dan kelengkapan solusi untuk setiap user story.

- Menunjukkan keterampilan dalam penanganan exception (misalnya negara penagihan yang belum diisi, format telepon yang tidak valid, dan sebagainya). Anda harus mencegah operasi trigger dan menampilkan pesan kesalahan yang mudah dipahami pengguna. Administrator Salesforce harus memiliki cara yang mudah untuk memperbarui dan mengelola pesan kesalahan tersebut.

- Mematuhi praktik terbaik penulisan kode Apex dan pedoman keamanan dalam pengembangan Apex dengan fokus pada skalabilitas kode.
- Efektivitas cakupan pengujian untuk memvalidasi **seluruh** kode Apex dengan cakupan pengujian minimal 90%.

- Memastikan seluruh kode siap digunakan di lingkungan produksi.

**2\. Asesmen Berbasis Skenario**

Anda ditugaskan merancang arsitektur solusi Salesforce untuk sebuah instansi pemerintah yang menawarkan layanan terkait pertanyaan dan masukan dari warga.

# Peran dan Tanggung Jawab

- **Administrator Cabang (Branch Admin)** - Perlu memantau semua permintaan yang masuk melalui berbagai kanal komunikasi warga di dalam divisinya. Mereka tidak terlibat langsung dalam penyelesaian kasus, tetapi memerlukan gambaran menyeluruh untuk keperluan pengelolaan dan pengawasan.

- **Supervisor** - Mengawasi agen dan memastikan bahwa mereka menangani kasus pertanyaan maupun masukan secara efektif, terlepas dari kanal komunikasi yang digunakan.

- **Agen (Agent)** - Berinteraksi langsung dengan warga, menangani pertanyaan sehari-hari, dan memproses masukan yang diterima melalui kanal komunikasi warga mana pun.

# Pengelolaan Kasus

**Kasus Pertanyaan (Enquiry Cases)**: Meliputi penanganan pertanyaan, kekhawatiran, atau permintaan informasi dari warga mengenai layanan instansi.

Gambaran umum proses kasus pertanyaan:

1. **Inisiasi** - Warga mengajukan pertanyaan melalui salah satu kanal yang tersedia.
2. **Verifikasi** - Agen memverifikasi data warga, terutama menggunakan nomor telepon atau email warga, dengan mencocokkannya terhadap sistem manajemen data induk eksternal.
3. **Pencatatan Kasus** - Informasi pertanyaan secara terperinci, beserta dokumen pendukung seperti foto, dicatat dalam sistem.
4. **Penugasan Kasus** - Sistem menugaskan kasus kepada agen berdasarkan kondisi seperti keahlian, bahasa, beban kerja, dan ketersediaan.
5. **Penyelesaian** - Agen menangani pertanyaan, dengan kemungkinan melibatkan Supervisor untuk kasus yang kompleks. Untuk kasus yang sudah memiliki solusi, agen memberikan solusi yang relevan. Jika belum, agen harus mengembangkan dan mendokumentasikan solusi baru.
6. **Tindak Lanjut** - Tindak lanjut secara berkala dengan warga harus dilakukan hingga kasus benar-benar terselesaikan.
7. **Penutupan** - Setelah terselesaikan, kasus ditutup dengan konfirmasi warga.

**Kasus Masukan (Feedback Cases)**: Melibatkan pemrosesan masukan, keluhan, atau saran warga mengenai layanan instansi.

Gambaran umum proses kasus masukan:

1. **Penerimaan** - Masukan diterima melalui kanal yang telah ditentukan.
2. **Pencatatan** - Detail masukan dicatat dalam sistem, termasuk layanan atau produk tertentu yang berkaitan dengan masukan tersebut.
3. **Analisis** - Agen menganalisis masukan untuk memahami tingkat kepuasan warga dan aspek yang perlu ditingkatkan.
4. **Tanggapan** - Jika diperlukan, agen memberikan tanggapan kepada warga.
5. **Pelaporan** - Masukan dihimpun untuk peninjauan internal sehingga dapat mendukung perbaikan dan perencanaan strategis.
6. **Evaluasi** - Supervisor meninjau proses penanganan masukan dan hasilnya untuk menilai kinerja agen serta tingkat kepuasan warga.

# Kanal Komunikasi

- Warga dapat mengajukan kasus langsung melalui situs web instansi.
- Warga dapat menelepon untuk melaporkan masalah atau mengajukan pertanyaan.
- Warga dapat memperoleh bantuan secara real-time melalui situs web atau aplikasi seluler instansi.
- Warga dapat mengirimkan pertanyaan atau masukan melalui email.

# Kebutuhan Tingkat Tinggi

- Sistem harus dapat terintegrasi dengan sistem manajemen data induk eksternal untuk verifikasi warga.
- Diperlukan fleksibilitas untuk beradaptasi terhadap perubahan.
- Penanganan data mencakup migrasi data selama 10 tahun yang berjumlah 6 juta record dan 100GB file.
- Mampu menangani 5.000 kasus baru dan unggahan file sebesar 100MB setiap hari.
- Mengimplementasikan Single Sign-On (SSO) menggunakan Microsoft Active Directory yang sudah ada.
- Sistem harus memungkinkan Administrator Cabang mengevaluasi kinerja setiap agen, dengan mempertimbangkan efektivitas mereka dalam menangani kasus melalui berbagai kanal komunikasi.

Tantangan Anda adalah merancang solusi yang memenuhi kebutuhan bisnis di atas. Kami akan membahas rancangan arsitektur solusi selama wawancara; harap bersiap untuk mempresentasikan dan menjelaskan alasan di balik rancangan Anda.

Solusi tersebut harus membahas secara menyeluruh aspek-aspek berikut, di antaranya:

- Lisensi, edisi, fitur Salesforce, dan alat pihak ketiga yang digunakan
- Diagram lanskap sistem
- Proses bisnis, misalnya user story
- Pertimbangan integrasi
- Pertimbangan model data, misalnya Entity-Relationship Diagram (ERD), pembagian akses data, dan rancangan keamanan
- Rencana migrasi data

| _Anda boleh membuat asumsi yang wajar untuk bagian ini. Ingat untuk menyatakan asumsi Anda dengan jelas._ |
| :-------------------------------------------------------------------------------------------------------: |

**3\. Penyerahan Hasil**

# Penyerahan Hasil Pemrograman

Setelah menyelesaikan tugas, harap berikan akses kepada kami ke Trailhead Playground Developer Org Anda dengan membuat akun pengguna Salesforce dengan detail berikut:

1. Email = NGCMP_test@hdb.gov.sg
2. Username = `<YourCompanyName>.<YourFirstName>@hdb.sf.review`  
   misalnya `UniversalContainers.John@hdb.sf.review`
3. Profile = `System Administrator`
4. Isi field wajib lainnya, misalnya LastName dan Alias.

Email verifikasi akan dikirim ke alamat email yang Anda tentukan di atas untuk peninjauan hasil pekerjaan Anda. Anda dapat menonaktifkan akun tersebut setelah peninjauan selesai.

# Penyerahan Hasil Berbasis Skenario

1. Sajikan solusi Anda dalam format yang sesuai, misalnya PowerPoint.

2. Di lingkungan Salesforce Anda, **unggah** rancangan solusi melalui Salesforce Files dan bagikan kepada akun pengguna Salesforce yang dibuat pada langkah penyerahan hasil pemrograman.

3. Anda perlu mempresentasikan solusi Anda. Demonstrasi solusi bersifat opsional.
