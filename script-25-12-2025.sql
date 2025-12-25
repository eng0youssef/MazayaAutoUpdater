-- 1. محاولة إدخال بيانات (المفروض السطر ده يتلغي لما الخطأ يحصل تحت)
INSERT INTO Test_Success_Table (Note) VALUES ('I should be deleted because of the error below');
GO

-- 2. الكارثة: خطأ في اسم الجدول (أو قسمة على صفر)
-- هنا كتبنا اسم جدول مش موجود أصلاً عشان يضرب Error
INSERT INTO Non_Existent_Table (Name) VALUES ('Error Here');
GO
