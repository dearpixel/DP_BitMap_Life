{
  Игра жизнь.
  Используется bitmap для отрисовки и работы с данными,
  поэтому есть свои особенности: при заполнении в циклах индекс
  пикселя = y * ширина + x, а индекс цвета определяется по порядку:
  0 - синий, 1 - зелёный, 2 - красный и 3 - прозрачность.
}

uses GraphABC, System.Drawing, System.Drawing.Imaging;

/// Создаёт изображение из массива байтов c ширина изображения Width
function BytesToImage(bytes: array of byte; Width: integer): Bitmap;
begin
  var Height := (bytes.Length div 4) div Width;
  result := new Bitmap(Width, Height);
  var rect := new Rectangle(0, 0, Width, Height);
  var bmData := result.LockBits(rect, ImageLockMode.WriteOnly, result.PixelFormat);
  System.Runtime.InteropServices.Marshal.Copy(bytes, 0, bmData.Scan0, bytes.Length);
  result.UnlockBits(bmData);
end;
/// Создаёт массива байтов из изображения
function ImageToBytes(bm: bitmap): array of byte;
begin
  var rect := new Rectangle(0, 0, bm.Width, bm.Height);
  var bmData := bm.LockBits(rect, ImageLockMode.ReadOnly, bm.PixelFormat);
  var Length := bmData.Stride * bm.Height;
  result := new byte[ Length];
  System.Runtime.InteropServices.Marshal.Copy(bmData.Scan0, result, 0, Length);
  bm.UnlockBits(bmData);
end;

var
  /// Ширина окна и массивов
  Width := 500;
  /// Основное хранилище информации
  bytes: Array of byte := new Byte[Width * Width * 4];
  /// Дублирующее хранилище для изменений
  buffer: Array of byte := new Byte[Width * Width * 4];
  /// Хранилище для отрисовки
  bm: Bitmap;

/// Подсчёт соседей
/// Возвращает 255 (Пусто), если соседей 2 или 3
/// Возвращает 0 (Занято) если их больше 3 или меньше 2
procedure SumAround(X, Y: integer);
var
  /// Обработка выхода за пределы поля
  MaxX, MaxY, MinX, MinY: integer;
  /// Сумма соседей
  Sum: byte;
begin
  // Ограничение обработки границ
  if X - 1 < 0 then MinX := Width - 1 else MinX := X - 1;
  if Y - 1 < 0 then MinY := (bytes.Length div 4) div Width - 1 else MinY := Y - 1;
  if X + 1 > Width - 1 then MaxX := 0 else MaxX := X + 1;
  if Y + 1 > (bytes.Length div 4) div Width - 1 then MaxY := 0 else MaxY := Y + 1;
  // Подсчёт соседей
  Sum := 0;
  if bytes[(MinY * Width + MinX) * 4] = 0 then Sum += 1;
  if bytes[(MinY * Width + X) * 4] = 0 then Sum += 1;
  if bytes[(MinY * Width + MaxX) * 4] = 0 then Sum += 1;
  if bytes[(Y * Width + MaxX) * 4] = 0 then Sum += 1;
  if bytes[(MaxY * Width + MaxX) * 4] = 0 then Sum += 1;
  if bytes[(MaxY * Width + X) * 4] = 0 then Sum += 1;
  if bytes[(MaxY * Width + MinX) * 4] = 0 then Sum += 1;
  if bytes[(Y * Width + MinX) * 4] = 0 then Sum += 1;
  // Удаление если соседей больше 3 или меньше 2
  if (Sum > 3) or (Sum < 2) then
  begin
    buffer[(Y * Width + X) * 4] := 255;
    buffer[(Y * Width + X) * 4 + 1] := 255;
    buffer[(Y * Width + X) * 4 + 2] := 255;
    buffer[(Y * Width + X) * 4 + 3] := 255;
  end;
  // Создание если соседей ровно 3
  if Sum = 3 then
  begin
    buffer[(Y * Width + X) * 4] := 0;
    buffer[(Y * Width + X) * 4 + 1] := 0;
    buffer[(Y * Width + X) * 4 + 2] := 0;
    buffer[(Y * Width + X) * 4 + 3] := 255;
  end;
end;

/// Заполнение поля случайными данными
procedure Randomize;
var
  /// Позиция начала пикселя
  i: integer;
  /// Новое значение пикселя
  value: integer;
begin
  for var x := 0 to Width - 1 do
    for var y := 0 to Bytes.Length div (Width * 4) - 1 do
    begin
      i := y * Width + x;
      value := Random(2) * 255;
      bytes[i * 4] := value; // Синий
      bytes[i * 4 + 1] := value; // Зелёный
      bytes[i * 4 + 2] := value; // Красный
      bytes[i * 4 + 3] := 255; // Прозрачный
    end;
end;

/// Подготовка данных к пуску программы
procedure Init;
begin
  SetWindowSize(Width, Width);
  SetWindowTitle('BitmapData LifeGame');
  Randomize;
end;

/// Отрисовка данных
procedure Render;
begin
  if bm <> nil then bm.Dispose;
  bm := BytesToImage(bytes, Width);
  System.Threading.Monitor.Enter(GraphABC.GraphABCControl);
  GraphWindowGraphics.DrawImage(bm, 0, 0);
  System.Threading.Monitor.Exit(GraphABC.GraphABCControl);
end;

/// Обновление логики
procedure Update;
begin
  //В цикле производим логические операции, и заносим результат в буфер
  for var x := 0 to Width - 1 do
    for var y := 0 to Bytes.Length div (Width * 4) - 1 do
      SumAround(x, y);
  //Переносим результат из буфера в основной массив для отрисовки
  for var i := 0 to Bytes.Length - 1 do
    bytes[i] := buffer[i];
  //bytes := buffer; // Если раскомментировать, получится интересный эффект
end;

/// Рабочий блок программы
begin
  Init;
  while True do
  begin
    Render;
    Update;
  end;
end.