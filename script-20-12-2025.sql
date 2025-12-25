-- 1. إنشاء جدول للتجربة
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Test_Success_Table')
BEGIN
    CREATE TABLE Test_Success_Table (
        ID INT IDENTITY(1,1), 
        Note NVARCHAR(50)
    );
END
GO

-- 2. إدخال بيانات
INSERT INTO Test_Success_Table (Note) VALUES ('This script ran successfully');
GO
