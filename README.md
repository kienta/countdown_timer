# Countdown Timer

Ung dung dem nguoc da nen tang (Android, iOS, Windows, macOS, Linux, Web) duoc xay dung bang Flutter.

## Tinh nang

- Tao nhieu bo dem nguoc cung luc
- Hien thi dong ho cat thoi gian voi hoat anh
- Am thanh canh bao khi het gio
- Thong bao he thong khi bo dem ket thuc
- Sap xep danh sach bo dem (theo ten, thoi gian con lai, ngay tao)
- Luu tru du lieu cuc bo voi SQLite
- Giao dien toi (dark theme), ho tro responsive tren nhieu kich thuoc man hinh

## Yeu cau

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- (Windows) Visual Studio 2022 voi C++ desktop workload
- (macOS) Xcode >= 14
- (Linux) Cac goi: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`

## Cai dat

1. Clone repository:

```bash
git clone <repo-url>
cd countdown_timer
```

2. Cai dat cac dependency:

```bash
flutter pub get
```

3. Chay ung dung:

```bash
# Chay tren thiet bi mac dinh
flutter run

# Chay tren Windows
flutter run -d windows

# Chay tren Chrome (web)
flutter run -d chrome

# Chay tren Android
flutter run -d android

# Chay tren iOS (chi tren macOS)
flutter run -d ios
```

## Su dung

1. **Tao bo dem**: Nhan nut **+** o goc phai phia tren de tao bo dem moi. Nhap ten va thiet lap thoi gian (gio, phut, giay).
2. **Bat dau/Tam dung**: Nhan vao the bo dem de mo man hinh dem nguoc. Su dung nut Play/Pause de dieu khien.
3. **Dat lai**: Nhan nut Reset de dat lai bo dem ve thoi gian ban dau.
4. **Sap xep**: Su dung dropdown "Sort by" tren thanh cong cu de sap xep danh sach bo dem.
5. **Xoa**: Vuot hoac nhan nut xoa tren the bo dem de xoa bo dem.
6. **Canh bao**: Khi bo dem ket thuc, ung dung se phat am thanh va hien thi thong bao he thong.

## Chay test

```bash
flutter test
```

## Cau truc du an

```
lib/
  main.dart                  # Diem vao ung dung
  models/
    timer_model.dart         # Mo hinh du lieu Timer
  screens/
    launcher_screen.dart     # Man hinh chinh (danh sach bo dem)
    timer_screen.dart        # Man hinh dem nguoc
  services/
    database_service.dart    # Quan ly SQLite
    timer_service.dart       # Logic quan ly bo dem
    notification_service.dart # Am thanh & thong bao
  theme/
    app_theme.dart           # Cau hinh giao dien
  utils/
    responsive.dart          # Ho tro responsive
    time_utils.dart          # Tien ich xu ly thoi gian
  widgets/
    create_timer_dialog.dart # Dialog tao bo dem
    hourglass_widget.dart    # Widget dong ho cat
    timer_card.dart          # The hien thi bo dem
```
