-- 1. التأكد أولاً: إنشاء جدول "سجل التحديثات" لو مش موجود
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Update_Test_Log')
BEGIN
    CREATE TABLE Update_Test_Log (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        Message NVARCHAR(200),
        UpdateDate DATETIME DEFAULT GETDATE()
    )
END
GO

-- 2. إدخال رسالة تثبت أن الاسكريبت بدأ يشتغل
INSERT INTO Update_Test_Log (Message) 
VALUES ('Start Update: Transaction Test Started');
GO

-- 3. تجربة تعديل الهيكل (Migration): إضافة عمود جديد للجدول
-- (الشرط ده عشان لو شغلت الاسكريبت مرتين ميضربش Error)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE Name = 'VersionNumber' AND Object_ID = Object_ID('Update_Test_Log'))
BEGIN
    ALTER TABLE Update_Test_Log ADD VersionNumber NVARCHAR(50) DEFAULT '1.0.0';
END
GO

-- 4. إدخال رسالة تثبت أن التعديل والاسكريبت خلصوا بنجاح
INSERT INTO Update_Test_Log (Message, VersionNumber) 
VALUES ('Success: Migration Completed Successfully', '1.0.2');
GO
