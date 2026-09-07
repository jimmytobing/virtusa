# [Auto] recalculateForApplications

API name: `Auto_recalculateForApplications`. Autolaunched Flow untuk menghitung ulang jadwal pencairan **satu Contact**.

## Input dan output

| Variabel       | Tipe                             | Arah   | Isi                                                       |
| -------------- | -------------------------------- | ------ | --------------------------------------------------------- |
| `varR_Contact` | Record Contact, bukan collection | Input  | `Id` Contact tersimpan dan `Support_Option__c` opsi baru. |
| `varT_Error`   | Text                             | Output | Kosong jika sukses; pesan jika validasi bisnis gagal.     |

Input null, Contact tanpa Id, atau opsi kosong menghasilkan `varT_Error` tanpa DML. Caller wajib memeriksa output sebelum melanjutkan jalur sukses. Interface lama `colR_Applicants` sudah dihapus; pemanggil lama harus mengganti mapping input.

```apex
Flow.Interview interview = Flow.Interview.createInterview(
  'Auto_recalculateForApplications',
  new Map<String, Object>{
    'varR_Contact' => new Contact(
      Id = applicantId,
      Support_Option__c = newSupportOptionId
    )
  }
);
interview.start();
String error = (String) interview.getVariableValue('varT_Error');
if (String.isNotBlank(error)) {
  // Tampilkan pesan dan hentikan jalur sukses di caller.
}
```

Di parent Flow, tambahkan Subflow dan langsung map record Contact ke `varR_Contact`. Simpan `varT_Error` ke Text variable, lalu gunakan Decision `Is Blank` untuk membedakan sukses dan gagal.

Caller boleh memasukkan opsi baru tanpa menyimpan perubahan pada Contact terlebih dahulu. Flow ini hanya mengubah disbursement, bukan menyimpan Contact.

## Alur perhitungan

1. Validasi Contact dan ambil satu `Support_Option__c` berdasarkan `varR_Contact.Support_Option__c`.
2. Ambil hanya disbursement paid milik Contact: `Grant_Applicant__c = varR_Contact.Id` dan `Grant_is_disbursed__c = true`.
3. Assignment **Count Received Months** memakai **Equals Count** untuk menghitung jumlah record paid. Satu **Loop Disbursements → Sum Received** menjumlah nominal dengan Assignment **Add**; nominal kosong dihitung nol.
4. Decision **Check Balance** memvalidasi total baru dan sisa bulan. Total baru = `Amount__c × Duration__c`, sisa nominal = total baru − total paid, sisa bulan = durasi − jumlah record paid.
5. Jika ada sisa nominal, buat jadwal mulai tanggal 1 bulan depan. Assignment **Build Disbursement** mengisi record, menambahnya ke koleksi insert, dan menaikkan nomor bulan. Decision **Check Month Number** mengulang proses sampai seluruh bulan selesai.
6. **Get Unpaid Disbursements** mengambil record milik Contact dengan `Grant_is_disbursed__c = false`. Decision memeriksa koleksinya sebelum **Delete Unpaid Disbursements**, kemudian insert koleksi baru jika ada sisa nominal. Koleksi hasil query langsung dipakai untuk delete; tidak perlu loop atau Assignment untuk mengumpulkannya.

Tidak ada query atau DML di dalam loop. Record paid dan record Contact lain tetap utuh. Jika total paid tepat sama dengan total baru, unpaid dihapus tanpa pengganti.

Assignment mendukung **Equals Count**, tetapi tidak menyediakan operator SUM untuk field pada seluruh record collection. Karena itu penjumlahan nominal tetap memakai satu loop pendek. Agregasi tanpa loop tersedia melalui Transform bila diperlukan. [Assignment operators](https://help.salesforce.com/s/articleView?id=platform.flow_ref_operators_assignment.htm&language=en_US&type=5), [Transform Sum/Count](https://help.salesforce.com/s/articleView?id=platform.flow_build_logic_transform_sum_or_count.htm&language=en_US&type=5).

`Grant_Disbursement__c.Grant_Applicant__c` menyimpan ID Contact; `Grant_Applicant__r` adalah relationship traversal. Field `Name` pada disbursement (label **Support Option**) menyimpan snapshot nama opsi.

Nominal bulanan mengikuti pembulatan currency dua desimal, tanpa koreksi bulan terakhir seperti algoritme asal: 100 / 3 menjadi tiga nominal 33.33.

## Error dan transaksi

Pesan diambil melalui `Auto_getMessage` dengan fallback:

- `DISBURSEMENT_OPTION_TOTAL_TOO_LOW`: total paid melebihi total baru.
- `DISBURSEMENT_OPTION_NO_MONTHS`: sisa nominal positif tetapi bulan tersisa nol/negatif.
- `DISBURSEMENT_INPUT_INVALID`: Contact/Id/opsi kosong.
- `SUPPORT_OPTION_UNAVAILABLE`: opsi tidak ditemukan atau konfigurasi nominal/durasi tidak valid.

Assignment **Set Error Output** mengisi `varT_Error` lalu mengakhiri Flow sebelum Delete/Create. Tidak ada action Apex tambahan. Error bisnis tidak melempar exception dan tidak otomatis membatalkan perubahan yang sudah dilakukan caller.

Fault platform, termasuk kegagalan query atau DML, tetap diteruskan sebagai fault. Jika caller menangkap fault, caller bertanggung jawab atas rollback yang diperlukan, terutama jika insert gagal setelah delete. Flow tidak memaksa system mode.

## Validasi

Dry-run `hdbsf` pada 7 September 2026 berhasil (`checkOnly: true`, ID `0Affj00000QAapfCAD`): **9 test lulus, 0 gagal**, coverage Flow **22/22 elemen (100%)**. Flow berkurang dari 34 menjadi 22 elemen, dan dari 4 Loop menjadi 1 Loop. Perubahan belum dideploy ke org.

`GrantRecalculationFlowTest` memeriksa output kosong pada sukses, pesan bisnis tanpa exception/DML, penjumlahan beberapa record paid, isolasi Contact lain, penggantian unpaid, jadwal baru tanpa record sebelumnya, total habis, total terlalu rendah, bulan habis, Contact/opsi kosong, opsi tidak tersedia, dan pembulatan.

```sh
sf project deploy start --dry-run \
  --source-dir force-app/main/default/flows/Auto_recalculateForApplications.flow-meta.xml \
  --source-dir force-app/main/default/classes/GrantRecalculationFlowTest.cls \
  --target-org hdbsf \
  --test-level RunSpecifiedTests --tests GrantRecalculationFlowTest --wait 10
```

Metadata sumber berstatus Active agar dapat dipanggil setelah deployment. Pembuatan file dan dry-run tidak menyimpan atau mengaktifkan Flow ke org.
