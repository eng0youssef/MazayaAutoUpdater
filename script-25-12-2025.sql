USE MazayaMax_DB
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--*********************************************** ( تحديث 15-12-2025 )  *******************************************************--
--اضافة اوبشن في صلاحيات المستخدم لربط اليوزر بعملاء مندوب محدد فقط للتعامل معهم وعدم الاطلاع علي حسابات عملاء مناديب اخري
--نقل اوبشن عدم السماح بالصرف بالسالب الي شاشة صلاحيات المستخدمين بدلا من شاشة الاعدادات
--اضافة امكانية عمل معادلة تعديل الاسعار الي شاشة فاتورة المشتريات لتعديل اسعار اصناف الفاتورة فقط 
--تم استبدال علامة الدولار ($) بالرمز العام للعملة الاجنية(¤) لعدم الالتباس في حسابات الاستيراد اذا كانت الحسابات بعملة غير الدولار
--اضافة رسالة تحذرية في شاشة تسجيل الدخول وعدم فتح البرنامج اذا كان اصدا البرنامج مختلف عن الداتابيز 
--في حالة اضافة الاصناف للفاتورة عن طريق التحديد المتعدد و تفعيل اوبشن البيع بالوحدة الكبري تلقائيا يتم اضافة الاصناف الي  الفاتورة بالوحدة الكبري 
--عند فتح شاشة صلاحيات المستخدم سيتم الذهاب مباشرة لبيانات اليوزر الحالي  
-- تم اضافة اوبشن في شاشة بيانات الشركة لتحديد عملة التفقيط في طباعة الفاتورة
--تم اضافة اوبش الي بيانات الصنف لتفعيل حد الطلب او ايقافة لكل صنف علي حده


IF COL_LENGTH('Company', 'CurMain') IS NULL
	BEGIN
		Alter TABLE [dbo].[Company] ADD [CurMain] [Nvarchar](10) NULL;
		Alter TABLE [dbo].[Company] ADD [CurSub] [Nvarchar](10) NULL;
	END
GO

iF COL_LENGTH('Users', 'IsMan') IS NULL
	BEGIN
		Alter TABLE [dbo].Users ADD [IsMan] [Bit] NOT NULL CONSTRAINT [DF_Users_IsMan]  DEFAULT ((0));
		Alter TABLE [dbo].Users ADD [ManID] [Int] NOT NULL CONSTRAINT [DF_Users_ManID]  DEFAULT ((0));
	END
GO

iF COL_LENGTH('Items', 'IsLimit') IS NULL
	BEGIN
		Alter TABLE [dbo].Items ADD [IsLimit] [Bit] NOT NULL CONSTRAINT [DF_Items_IsLimit]  DEFAULT ((1));
	END
GO


	Update Company Set [CurMain] =N'جنية' ,[CurSub] =N'قرش' Where CurMain Is Null;
GO
	Update Users Set [IsMan]=0, [ManID]=0 Where [IsMan] Is NULL
GO		

ALTER PROCEDURE [dbo].[Insert-Items]
@Item_ID int,
@ItemCode Int,
@ItemName nvarchar(100),
@Bar1 Nvarchar(20),
@Bar2 Nvarchar(20),
@Bar3 Nvarchar(20),
@IsTasnea Bit,
@Price0 float,
@DiscPer0 float,
@Disc0 float,
@Price1 float,
@DiscPer1 float,
@Disc1 float,
@Price2 float,
@DiscPer2 float,
@Disc2 float,
@Price3 float,
@DiscPer3 float,
@Disc3 float,
@Price4 float,
@DiscPer4 float,
@Disc4 float,
@Imp_Price float,
@IsLimit Bit,
@Limit float,
@UnitID int,
@Unit2 int,
@Unit2Qty float,
@Unit3 int,
@Unit3Qty float,
@GroupID int,
@PlaceID int,
@Notes nvarchar(150),
@IsService bit,
@MinPrice Float=0,
@MaxPrice Float=0,
@MinQty Float=0,
@MaxQty Float=0,
@Photo Image,
@IsPhoto Bit,
@Active bit,
@MyDate datetime = N'2000-01-01',
@MyUser nvarchar(100),
@IsTaskAvrg Bit,
@IsImport Bit = 0,
@IsNewPrice Bit =0

AS 

Begin
	SET NOCOUNT ON;
	Set @MyUser =  Replace(@MyUser,'#Now#',FORMAT(GETDATE(), 'dd-MM-yyyy hh:mm:ss tt'))
	Set @MyDate = GETDATE()
	If (Select Item_ID From Items Where Item_ID=0) Is Null
		Begin
			insert into Items (Item_ID,	ItemCode,ItemName,Bar1,IsTasnea,Price0,DiscPer0,Disc0,
						       Price1,DiscPer1,Disc1,Price2,DiscPer2,Disc2,Price3,DiscPer3,Disc3,
							   Price4,DiscPer4,Disc4,Imp_Price,Limit,IsLimit,UnitID,Unit2,Unit2Qty,Unit3,Unit3Qty,
							   GroupID,PlaceID,Notes,IsService,MinPrice,MaxPrice,MinQty,MaxQty,
							   Photo,IsPhoto,Active,MyDate,MyUser,UserEdit)
			Select 0 Item_ID, 0 ItemCode, N'.' ItemName, 0 Bar1, 0 IsTasnea, 0 Price0, 0 DiscPer0, 0 Disc0, 
				   0 Price1, 0 DiscPer1, 0 Disc1, 0 Price2, 0 DiscPer2, 0 Disc2, 0 Price3, 0 DiscPer3, 0 Disc3,
				   0 Price4, 0 DiscPer4, 0 Disc4, 0 Imp_Price, 0 Limit, 0 IsLimit, 1 UnitID, 0 Unit2, 0 Unit2Qty, 0 Unit3, 0 Unit3Qty,
				   0 GroupID, 0 PlaceID, N'' Notes, 1 IsService, 0 MinPrice, 0 MaxPrice, 0 MinQty, 0 MaxQty, 
				   NULL Photo, NULL IsPhoto, 1 Active, GETDATE() MyDate, N'Admin' MyUser, '' UserEdit
		End
		
	If @IsImport = 1 
		Begin
			If ISNULL((Select Count(ItemCode) From Items Where ItemCode=@ItemCode),0) > 0  Set @ItemCode = NULL
		End

		If @Item_ID Is NULL Set @Item_ID = IsNULL((Select Max(Item_ID) From Items),0)+1
		If @ItemCode Is NULL Set @ItemCode = IsNULL((Select Max(ItemCode) From Items),0)+1
		If Len(IsNULL(@Bar1,N'')) =0 Set @Bar1 = @ItemCode
						----- التحقق من عدم تكرار اي باركود -----
		Declare @BarcodeErr Nvarchar(100)=
				IsNULL((Select Top 1 ItemName From Items Left Join Item_Barcode On Items.Item_ID = Item_Barcode.ItemID 
						Where Item_ID <> @Item_ID And(IsNull(Barcode,N'None')=@Bar1 Or IsNull(Barcode,N'None')=@Bar2 Or IsNull(Barcode,N'None')=@Bar3  
						OR IsNULL(Bar1,N'None') = @Bar1 OR IsNULL(Bar2,N'None') = @Bar1 OR IsNULL(Bar3,N'None') = @Bar1
						OR IsNULL(Bar1,N'None') = @Bar2 OR IsNULL(Bar2,N'None') = @Bar2 OR IsNULL(Bar3,N'None') = @Bar2
						OR IsNULL(Bar1,N'None') = @Bar3 OR IsNULL(Bar2,N'None') = @Bar3 OR IsNULL(Bar3,N'None') =@Bar3)),N'-')

		If @BarcodeErr <> N'-'
			Begin 
				Select N'-3|-3|' + @BarcodeErr
			End 
		Else
			Begin
				insert into Items (
						Item_ID,
						ItemCode,
						ItemName,
						Bar1,
						Bar2,
						Bar3,
						IsTasnea,
						Price0,
						DiscPer0,
						Disc0,
						Price1,
						DiscPer1,
						Disc1,
						Price2,
						DiscPer2,
						Disc2,
						Price3,
						DiscPer3,
						Disc3,
						Price4,
						DiscPer4,
						Disc4,
						Imp_Price,
						IsLimit,
						Limit,
						UnitID,
						Unit2,
						Unit2Qty,
						Unit3,
						Unit3Qty,
						GroupID,
						PlaceID,
						Notes,
						IsService,
						MinPrice,
						MaxPrice,
						MinQty,
						MaxQty,
						Photo,
						IsPhoto,
						Active,
						MyDate,
						MyUser,
						UserEdit)
				Values(
						@Item_ID,
						@ItemCode,
						@ItemName,
						@Bar1,
						@Bar2,
						@Bar3,
						@IsTasnea,
						@Price0,
						@DiscPer0,
						@Disc0,
						@Price1,
						@DiscPer1,
						@Disc1,
						@Price2,
						@DiscPer2,
						@Disc2,
						@Price3,
						@DiscPer3,
						@Disc3,
						@Price4,
						@DiscPer4,
						@Disc4,
						@Imp_Price,
						@IsLimit,
						@Limit,
						@UnitID,
						@Unit2,
						@Unit2Qty,
						@Unit3,
						@Unit3Qty,
						@GroupID,
						@PlaceID,
						@Notes,
						@IsService,
						@MinPrice,
						@MaxPrice,
						@MinQty,
						@MaxQty,
						@Photo,
						@IsPhoto,
						@Active,
						@MyDate,
						@MyUser,
						NULL)


				Exec dbo.Set_Item_Stock @Item_ID,@MyDate,@IsTaskAvrg --- تحديث رصيد الصنف ---
				Select Cast(@Item_ID As Nvarchar(20)) + N'|' +  Cast(@ItemCode As Nvarchar(20))
			End
End

GO

ALTER PROCEDURE [dbo].[Update-Items] 
@Item_ID int,
@ItemCode Int,
@ItemName nvarchar(100),
@Bar1 Nvarchar(20),
@Bar2 Nvarchar(20),
@Bar3 Nvarchar(20),
@IsTasnea Bit,
@Price0 float,
@DiscPer0 float,
@Disc0 float,
@Price1 float,
@DiscPer1 float,
@Disc1 float,
@Price2 float,
@DiscPer2 float,
@Disc2 float,
@Price3 float,
@DiscPer3 float,
@Disc3 float,
@Price4 float,
@DiscPer4 float,
@Disc4 float,
@Imp_Price float=NULL,
@IsLimit bit,
@Limit float,
@UnitID int,
@Unit2 int,
@Unit2Qty float,
@Unit3 int,
@Unit3Qty float,
@GroupID int,
@PlaceID int,
@Notes nvarchar(150),
@IsService bit,
@MinPrice Float=0,
@MaxPrice Float=0,
@MinQty Float=0,
@MaxQty Float=0,
@Photo Image,
@IsPhoto Bit,
@Active bit,
@IsNewPrice Bit =0,
@IsDataOnly Bit=0,
@MyDate datetime = N'2000-01-01',
@MyUser nvarchar(100),
@IsTaskAvrg Bit

AS 

Begin --1--
	SET NOCOUNT ON;
	Set @MyUser =  Replace(@MyUser,'#Now#',FORMAT(GETDATE(), 'dd-MM-yyyy hh:mm:ss tt'))

	Declare @OldIsTasnea Bit = IsNUll((Select IsTasnea From Items Where Item_ID=@Item_ID),@IsTasnea)
	Declare @CountInv Int = 0 --,@BarcodeErr Nvarchar(100) 
	If @IsTasnea <> @OldIsTasnea  
		Begin --2--
			Set @CountInv = IsNULL((Select Count(ItemID) From( 
                       					Select ItemID From Sales_Sub 
							 UNION ALL  Select ItemID From ReSales_Sub 
							 UNION ALL  Select ItemID From Buy_Sub 
							 UNION ALL  Select ItemID From ReBuy_Sub 
							 UNION ALL  Select ItemID From PreSales_Sub 
							 UNION ALL  Select ItemID From SalesTax_Sub 
							 UNION ALL  Select ItemID From ReSalesTax_Sub 
							 UNION ALL  Select ItemID From BuyTax_Sub 
							 UNION ALL  Select ItemID From ReBuyTax_Sub 
							 UNION ALL  Select ItemID From Ezn_In_Sub 
							 UNION ALL  Select ItemID From Ezn_Out_Sub 
							 UNION ALL  Select ItemID From Ezn_Tahwel_Sub 
							 UNION ALL  Select ItemID From Ezn_Tasnea_Sub 
							 UNION ALL  Select ItemID From Ezn_Tasnea 
							 UNION ALL  Select ItemID From Import_Items) AS CombinedItems
                        WHERE ItemID=@Item_ID), 0)
		End	 --2--
	If @CountInv >0
		Begin --3--
			Select N'-1|-1'
		End --3--
	Else
		Begin --4--
			Declare @OldIsService Bit = IsNUll((Select IsService From Items Where Item_ID=@Item_ID),@IsTasnea)
			If @IsService <> @OldIsService  
				Begin --5--
					Set @CountInv = IsNULL((Select Count(ItemID) From( 
                       					Select ItemID From Sales_Sub 
								UNION ALL  Select ItemID From ReSales_Sub 
								UNION ALL  Select ItemID From Buy_Sub 
								UNION ALL  Select ItemID From ReBuy_Sub 
								UNION ALL  Select ItemID From PreSales_Sub 
								UNION ALL  Select ItemID From SalesTax_Sub 
								UNION ALL  Select ItemID From ReSalesTax_Sub 
								UNION ALL  Select ItemID From BuyTax_Sub 
								UNION ALL  Select ItemID From ReBuyTax_Sub 
								UNION ALL  Select ItemID From Ezn_In_Sub 
								UNION ALL  Select ItemID From Ezn_Out_Sub 
								UNION ALL  Select ItemID From Ezn_Tahwel_Sub 
								UNION ALL  Select ItemID From Ezn_Tasnea_Sub 
								UNION ALL  Select ItemID From Ezn_Tasnea 
								UNION ALL  Select ItemID From Import_Items) AS CombinedItems
						WHERE ItemID=@Item_ID), 0)
				End	--5--

			If @CountInv >0
				Begin --6--
					Select N'-2|-2'
				End --6--
			Else
				Begin --7--
					If @ItemCode Is NULL Set @ItemCode = IsNULL((Select Max(ItemCode) From Items),0)+1
					If Len(IsNULL(@Bar1,N'')) =0 Set @Bar1 = @ItemCode
										----- التحقق من عدم تكرار اي باركود -----
					Declare @BarcodeErr Nvarchar(100)=
						IsNULL((Select Top 1 ItemName From Items Left Join Item_Barcode On Items.Item_ID = Item_Barcode.ItemID 
								Where Item_ID <> @Item_ID And(IsNull(Barcode,N'None')=@Bar1 Or IsNull(Barcode,N'None')=@Bar2 Or IsNull(Barcode,N'None')=@Bar3  
								OR IsNULL(Bar1,N'None') = @Bar1 OR IsNULL(Bar2,N'None') = @Bar1 OR IsNULL(Bar3,N'None') = @Bar1
								OR IsNULL(Bar1,N'None') = @Bar2 OR IsNULL(Bar2,N'None') = @Bar2 OR IsNULL(Bar3,N'None') = @Bar2
								OR IsNULL(Bar1,N'None') = @Bar3 OR IsNULL(Bar2,N'None') = @Bar3 OR IsNULL(Bar3,N'None') =@Bar3)),N'-')
				
					If @BarcodeErr <> N'-'
						Begin --8--
							Select N'-3|-3|' + @BarcodeErr
						End --8--
					Else
						Begin --9--
							
							Update Items SET 
								ItemCode=@ItemCode, 
								ItemName=@ItemName, 
								Bar1=@Bar1,
								Bar2=@Bar2,
								Bar3=@Bar3,
								IsTasnea=@IsTasnea, 
								Price0=@Price0, 
								DiscPer0=@DiscPer0, 
								Disc0=@Disc0, 
								Price1=@Price1, 
								DiscPer1=@DiscPer1, 
								Disc1=@Disc1, 
								Price2=@Price2,
								DiscPer2=@DiscPer2,  
								Disc2=@Disc2, 
								Price3=@Price3, 
								DiscPer3=@DiscPer3, 
								Disc3=@Disc3, 
								Price4=@Price4, 
								DiscPer4=@DiscPer4, 
								Disc4=@Disc4,
								Imp_Price=IsNULL(@Imp_Price,Imp_Price),
								IsLimit=@IsLimit, 
								Limit=@Limit, 
								UnitID=@UnitID, 
								Unit2=@Unit2, 
								Unit2Qty=@Unit2Qty, 
								Unit3=@Unit3, 
								Unit3Qty=@Unit3Qty, 
								GroupID=@GroupID, 
								PlaceID=@PlaceID, 
								Notes=@Notes, 
								IsService=@IsService, 
								MinPrice=@MinPrice,
								MaxPrice=@MaxPrice,
								MinQty=@MinQty,
								MaxQty=@MaxQty,
								Photo=@Photo,
								IsPhoto=@IsPhoto,
								Active=@Active, 
								IsNewPrice=@IsNewPrice,
								UserEdit=@MyUser
							Where
								Item_ID=@Item_ID 

							If @IsService = 1 Delete From Open_Stock Where ItemID=@Item_ID
							If @IsTasnea = 0 Delete From Kart_Tasnea Where MainItem=@Item_ID
							If @IsDataOnly = 0 --- تحديث البيانات والمخزون ومتوسط التكلفة ايضا ---
								Begin
									Set @MyDate=GETDATE()
									Exec dbo.Set_Item_Stock @Item_ID,@MyDate,@IsTaskAvrg --- تحديث رصيد الصنف ---
								End
							Select Cast(@Item_ID As Nvarchar(20)) + N'|' +  Cast(@ItemCode As Nvarchar(20))
						End --9--
				End --7--
		End --4--
End --1--



GO

ALTER PROCEDURE [dbo].[Rep_نواقص_حد_الطلب]
@ItemID Int,
@GroupID Int,
@KGroupID Int,
@Pricing Tinyint,
@SortBy Tinyint

AS
BEGIN
	SET NOCOUNT ON;

	Declare @Store1 As Nvarchar(50) ,@Store2 As Nvarchar(50) ,@Store3 As Nvarchar(50) ,@Store4 As Nvarchar(50) ,@Store5 As Nvarchar(50), 
			@Store6 As Nvarchar(50) ,@Store7 As Nvarchar(50) ,@Store8 As Nvarchar(50) ,@Store9 As Nvarchar(50) ,@Store10 As Nvarchar(50) 

	Declare @MyStore Int =-2,@Id SmallInt =1,@StoreName As Nvarchar(50)

	While @Id <=10 
		Begin
			If @MyStore<>-1 Set @MyStore =IsNULL((Select Min(StoreID) From Stock Where StoreID>@MyStore ),-1)
			Set @StoreName =IsNUll((Select StoreName From Stores Where Store_ID=@MyStore),'-')
			If @ID=1 Set @Store1=@StoreName
			If @ID=2 Set @Store2=@StoreName
			If @ID=3 Set @Store3=@StoreName
			If @ID=4 Set @Store4=@StoreName
			If @ID=5 Set @Store5=@StoreName
			If @ID=6 Set @Store6=@StoreName
			If @ID=7 Set @Store7=@StoreName
			If @ID=8 Set @Store8=@StoreName
			If @ID=9 Set @Store9=@StoreName
			If @ID=10 Set @Store10=@StoreName
			Set @StoreName ='-'
			Set @Id = @ID+1
		End


	SELECT  
		Item_Group.GroupName, 
		Items.ItemCode, 
		Items.ItemName, 
		Sum(Stock.Qty) Bal,
		Cast(Sum(Stock.Qty) - (Case When Unit2Qty <> 0 Then Cast(Sum(Stock.Qty)/Unit2Qty As Int) *Unit2Qty Else 0 End) As Nvarchar(20)) + Units.UnitName +
		Case When 
			Case When Unit2Qty <> 0 Then Cast(Sum(Stock.Qty)/Unit2Qty As Int) Else 0 End <> 0 Then 
				N' و ' + Cast(Case When Unit2Qty <> 0 Then Cast(Sum(Stock.Qty)/Unit2Qty As Int) Else 0 End As Nvarchar(20))+ 
				Case When Unit2Qty <> 0 Then Units_Big.UnitName + N'×' + Cast(Unit2Qty As Nvarchar(10)) Else N'' End  
			Else N'' End As QtyByUnit,
		Items.Limit, 
		Items.Limit-Sum(Stock.Qty) As Baky,
		Cast((Items.Limit-Sum(Stock.Qty)) - (Case When Unit2Qty <> 0 Then Cast((Items.Limit-Sum(Stock.Qty))/Unit2Qty As Int) *Unit2Qty Else 0 End) as Nvarchar(20)) + Units.UnitName +
		Case When 
			Case When Unit2Qty <> 0 Then Cast((Items.Limit-Sum(Stock.Qty))/Unit2Qty As Int) Else 0 End <> 0 Then 
				N' و ' + Cast(Case When Unit2Qty <> 0 Then Cast((Items.Limit-Sum(Stock.Qty))/Unit2Qty As Int) Else 0 End As Nvarchar(20))+ 
				Case When Unit2Qty <> 0 Then Units_Big.UnitName + N'×' + Cast(Unit2Qty As Nvarchar(10)) Else N'' End  
			Else N'' End As BakyByUnit,
		Case @Pricing When 0 Then Price0-Disc0 
			When 1 Then Price1-Disc1 
			When 2 Then Price2-Disc2
			When 3 Then Price3-Disc3 
			When 4 Then Price4-Disc4 
			When 5 Then AvrgCost
			When 6 Then dbo.Get_Item_Cost(Stock.ItemID,6,N'3000-12-31')  Else 0 End As Cost, 
		Cast(0 As float) As TotalCost,
		Sum(Case When Stores.StoreName = @Store1 Then Stock.Qty Else 0 End) As Store1,
		Sum(Case When Stores.StoreName = @Store2 Then Stock.Qty Else 0 End) As Store2,
		Sum(Case When Stores.StoreName = @Store3 Then Stock.Qty Else 0 End) As Store3,
		Sum(Case When Stores.StoreName = @Store4 Then Stock.Qty Else 0 End) As Store4,
		Sum(Case When Stores.StoreName = @Store5 Then Stock.Qty Else 0 End) As Store5,
		Sum(Case When Stores.StoreName = @Store6 Then Stock.Qty Else 0 End) As Store6,
		Sum(Case When Stores.StoreName = @Store7 Then Stock.Qty Else 0 End) As Store7,
		Sum(Case When Stores.StoreName = @Store8 Then Stock.Qty Else 0 End) As Store8,
		Sum(Case When Stores.StoreName = @Store9 Then Stock.Qty Else 0 End) As Store9,
		Sum(Case When Stores.StoreName = @Store10 Then Stock.Qty Else 0 End) As Store10,
		Stock.ItemID,
		Items.UnitID As Unit_ID
	FROM Items INNER JOIN Stock On Items.Item_ID = Stock.ItemID
		Inner Join Item_Group ON Items.GroupID = Item_Group.Group_ID 
		Inner Join Units ON Units.Unit_ID = Items.UnitID 
		LEFT JOIN Units AS Units_Big ON Items.Unit2 = Units_Big.Unit_ID
		Left join Stores On Stock.StoreID = Stores.Store_ID
	Where
			Items.Item_ID = IsNULL(@ItemID,Items.Item_ID)
		And Item_Group.Group_ID = IsNULL(@GroupID,Item_Group.Group_ID)
		And Item_Group.K_GroupID = IsNULL(@KGroupID,Item_Group.K_GroupID)
		And Items.IsLimit=1
	Group By
		Item_Group.Group_ID,
		Item_Group.GroupName,
		Item_Group.K_GroupID,
		ItemID,
		Items.ItemCode,
		Items.ItemName,
		Items.UnitID,
		Units.UnitName,
		Units_Big.UnitName,
		Unit2Qty,
		Items.Limit,
		Price0-Disc0 ,
		Price1-Disc1,
		Price2-Disc2, 
		Price3-Disc3,
		Price4-Disc4,
		AvrgCost
	Having 
		Items.Limit-Sum(Stock.Qty)>0 
	Order By 
		Case @SortBy When 0 Then Stock.ItemID When 2 Then Item_Group.Group_ID End,
		Case @SortBy When 1 Then ItemName End

	Select @Store1,@Store2,@Store3,@Store4,@Store5,@Store6,@Store7,@Store8,@Store9,@Store10

END

GO

ALTER PROCEDURE [dbo].[Rep_ارصدة_المخازن]
@Date2 DateTime,
@ItemID Int,
@StoreID Int,
@GroupID Int,
@KGroupID Int,
@BranID Int,
@Pricing Tinyint,
@SortBy Tinyint,
@HideZero Bit,
@RepType TinyInt,
@FolderPath Nvarchar(100)=N''

AS
BEGIN
	SET NOCOUNT ON;

	Set @Date2 = Cast(CAST(IsNull(@Date2,'3000-12-31') AS Date) As DateTime) + '23:59:59.997';
	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
	CREATE TABLE #Result(MyStore Int, MyItem Int, QtyAll Float)

Insert Into #Result ----| الرصيد الافتتاحي |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From Open_Stock Inner Join Items On Open_Stock.ItemID = Items.Item_ID
		            Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Open_Stock.OpenDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Open_Stock.StoreID = IsNull(@StoreID,Open_Stock.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
	Group By 
		Open_Stock.StoreID,
		Open_Stock.ItemID
		

Insert Into #Result ----| مشتريات |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From Buy inner Join Buy_Sub On Buy.Buy_ID = Buy_Sub.BuyID 
		 Inner Join Customers On Buy.SuppID = Customers.Cus_ID 
		 Inner Join Items On Buy_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Buy.BuyDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Buy_Sub.StoreID = IsNull(@StoreID,Buy_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Buy.BranID = IsNull(@BranID,Buy.BranID)
	Group By 
		Buy_Sub.StoreID,
		Buy_Sub.ItemID


Insert Into #Result ----| مرتجع مشتريات |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)*-1
	From ReBuy inner Join ReBuy_Sub On ReBuy.Buy_ID = ReBuy_Sub.BuyID 
		 Inner Join Customers On ReBuy.SuppID = Customers.Cus_ID
		 Inner Join Items On ReBuy_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			ReBuy.BuyDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And ReBuy_Sub.StoreID = IsNull(@StoreID,ReBuy_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And ReBuy.BranID = IsNull(@BranID,ReBuy.BranID)
	Group By 
		ReBuy_Sub.StoreID,
		ReBuy_Sub.ItemID



Insert Into #Result ----| مشتريات ضريبي |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From BuyTax inner Join BuyTax_Sub On BuyTax.Buy_ID = BuyTax_Sub.BuyID  
		 Inner Join Customers On BuyTax.SuppID = Customers.Cus_ID
		 Inner Join Items On BuyTax_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			BuyTax.BuyDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And BuyTax_Sub.StoreID = IsNull(@StoreID,BuyTax_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And BuyTax.BranID = IsNull(@BranID,BuyTax.BranID)
	Group By 
		BuyTax_Sub.StoreID,
		BuyTax_Sub.ItemID



Insert Into #Result ----| مرتجع مشتريات ضريبي |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)*-1
	From ReBuyTax inner Join ReBuyTax_Sub On ReBuyTax.Buy_ID = ReBuyTax_Sub.BuyID  
		 Inner Join Customers On ReBuyTax.SuppID = Customers.Cus_ID
		 Inner Join Items On ReBuyTax_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			ReBuyTax.BuyDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And ReBuyTax_Sub.StoreID = IsNull(@StoreID,ReBuyTax_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And ReBuyTax.BranID = IsNull(@BranID,ReBuyTax.BranID)
	Group By 
		ReBuyTax_Sub.StoreID,
		ReBuyTax_Sub.ItemID



Insert Into #Result ----| مبيعات |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)*-1
	From Sales inner Join Sales_Sub On Sales.Sales_ID = Sales_Sub.SalesID  
		 Inner Join Customers On Sales.CusID = Customers.Cus_ID
		 Inner Join Items On Sales_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Sales.SalesDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Sales_Sub.StoreID = IsNull(@StoreID,Sales_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Sales.BranID = IsNull(@BranID,Sales.BranID)
	Group By 
		Sales_Sub.StoreID,
		Sales_Sub.ItemID



Insert Into #Result ----| مرتجع مبيعات |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From ReSales inner Join ReSales_Sub On ReSales.Sales_ID = ReSales_Sub.SalesID 
		 Inner Join Customers On ReSales.CusID = Customers.Cus_ID
		 Inner Join Items On ReSales_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			ReSales.SalesDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And ReSales_Sub.StoreID = IsNull(@StoreID,ReSales_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And ReSales.BranID = IsNull(@BranID,ReSales.BranID)
	Group By 
		ReSales_Sub.StoreID,
		ReSales_Sub.ItemID



Insert Into #Result ----| مبيعات ضريبي |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)*-1
	From SalesTax inner Join SalesTax_Sub On SalesTax.Sales_ID = SalesTax_Sub.SalesID  
		 Inner Join Customers On SalesTax.CusID = Customers.Cus_ID
		 Inner Join Items On SalesTax_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			SalesTax.SalesDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And SalesTax_Sub.StoreID = IsNull(@StoreID,SalesTax_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And SalesTax.BranID = IsNull(@BranID,SalesTax.BranID)
	Group By 
		SalesTax_Sub.StoreID,
		SalesTax_Sub.ItemID



Insert Into #Result ----| مرتجع مبيعات ضريبي |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From ReSalesTax inner Join ReSalesTax_Sub On ReSalesTax.Sales_ID = ReSalesTax_Sub.SalesID  
	     Inner Join Customers On ReSalesTax.CusID = Customers.Cus_ID
		 Inner Join Items On ReSalesTax_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			ReSalesTax.SalesDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And ReSalesTax_Sub.StoreID = IsNull(@StoreID,ReSalesTax_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And ReSalesTax.BranID = IsNull(@BranID,ReSalesTax.BranID)
	Group By 
		ReSalesTax_Sub.StoreID,
		ReSalesTax_Sub.ItemID



Insert Into #Result ----| اذن اضافة |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From Ezn_In inner Join Ezn_In_Sub On Ezn_In.Ezn_ID = Ezn_In_Sub.EznID
		 Inner Join Items On Ezn_In_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Ezn_In.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_In_Sub.StoreID = IsNull(@StoreID,Ezn_In_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_In.BranID = IsNull(@BranID,Ezn_In.BranID)
	Group By 
		Ezn_In_Sub.StoreID,
		Ezn_In_Sub.ItemID



Insert Into #Result ----| اذن صرف |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)*-1
	From Ezn_Out inner Join Ezn_Out_Sub On Ezn_Out.Ezn_ID = Ezn_Out_Sub.EznID
		 Inner Join Items On Ezn_Out_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Ezn_Out.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_Out_Sub.StoreID = IsNull(@StoreID,Ezn_Out_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_Out.BranID = IsNull(@BranID,Ezn_Out.BranID)
	Group By 
		Ezn_Out_Sub.StoreID,
		Ezn_Out_Sub.ItemID



Insert Into #Result ----| اذن تصنيع تام |----
	Select 
		StoreID,
		ItemID,
		Sum(Qty)
	From Ezn_Tasnea Inner Join Items On Ezn_Tasnea.ItemID = Items.Item_ID
					Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Ezn_Tasnea.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_Tasnea.StoreID = IsNull(@StoreID,Ezn_Tasnea.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_Tasnea.BranID = IsNull(@BranID,Ezn_Tasnea.BranID)
	Group By 
		Ezn_Tasnea.StoreID,
		Ezn_Tasnea.ItemID



Insert Into #Result ----| اذن صرف خامات تصنيع |----
	Select 
		Ezn_Tasnea_Sub.StoreID,
		Ezn_Tasnea_Sub.ItemID,
		Sum(Ezn_Tasnea_Sub.Qty)*-1
	From Ezn_Tasnea inner Join Ezn_Tasnea_Sub On Ezn_Tasnea.Ezn_ID = Ezn_Tasnea_Sub.EznID 
		 inner Join Items On Ezn_Tasnea_Sub.ItemID= Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID 
	Where
			Ezn_Tasnea.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_Tasnea_Sub.StoreID = IsNull(@StoreID,Ezn_Tasnea_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_Tasnea.BranID = IsNull(@BranID,Ezn_Tasnea.BranID)
	Group By 
		Ezn_Tasnea_Sub.StoreID,
		Ezn_Tasnea_Sub.ItemID


Insert Into #Result ----| اذن تحويل صادر |----
	Select StoreID,ItemID,Sum(QtyAll)*-1
	From Ezn_Tahwel inner Join Ezn_Tahwel_Sub On Ezn_Tahwel.Ezn_ID = Ezn_Tahwel_Sub.EznID 
		 Inner Join Stores On Ezn_Tahwel.StoreTo = Stores.Store_ID
		 Inner Join Items On Ezn_Tahwel_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Ezn_Tahwel.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_Tahwel_Sub.StoreID = IsNull(@StoreID,Ezn_Tahwel_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_Tahwel.BranID = IsNull(@BranID,Ezn_Tahwel.BranID)
	Group By 
		Ezn_Tahwel_Sub.StoreID,
		Ezn_Tahwel_Sub.ItemID



Insert Into #Result ----| اذن تحويل وارد |----
	Select 
		Ezn_Tahwel.StoreTo,
		ItemID,
		Sum(QtyAll)
	From Ezn_Tahwel inner Join Ezn_Tahwel_Sub On Ezn_Tahwel.Ezn_ID = Ezn_Tahwel_Sub.EznID 
	     Inner Join Stores On Ezn_Tahwel_Sub.StoreID = Stores.Store_ID
		 Inner Join Items On Ezn_Tahwel_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Ezn_Tahwel.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_Tahwel.StoreTo = IsNull(@StoreID,Ezn_Tahwel.StoreTo)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_Tahwel.BranID = IsNull(@BranID,Ezn_Tahwel.BranID)
	Group By 
		Ezn_Tahwel.StoreTo,
		Ezn_Tahwel_Sub.ItemID

	
Insert Into #Result ----| اذن تسوية |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From Ezn_Taswea inner Join Ezn_Taswea_Sub On Ezn_Taswea.Ezn_ID = Ezn_Taswea_Sub.EznID
		 Inner Join Items On Ezn_Taswea_Sub.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Ezn_Taswea.EznDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Ezn_Taswea_Sub.StoreID = IsNull(@StoreID,Ezn_Taswea_Sub.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
		And Ezn_Taswea.BranID = IsNull(@BranID,Ezn_Taswea.BranID)
	Group By 
		Ezn_Taswea_Sub.StoreID,
		Ezn_Taswea_Sub.ItemID
		

	
Insert Into #Result ----| استيراد |----
	Select 
		StoreID,
		ItemID,
		Sum(QtyAll)
	From Import_Invoice inner Join Import_Items On Import_Invoice.Inv_ID = Import_Items.InvID 
		 Inner Join Customers On Import_Invoice.SuppID = Customers.Cus_ID 
		 Inner Join Items On Import_Items.ItemID = Items.Item_ID
		 Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Import_Invoice.InvDate <=@Date2
		And Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Import_Items.StoreID = IsNull(@StoreID,Import_Items.StoreID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
	Group By 
		Import_Items.StoreID,
		Import_Items.ItemID
	
	
		
	Insert Into #Result ----| اضافة كل الاصناف |----	
	SELECT 
		Stores.Store_ID, 
		Items.Item_ID,
		0
	FROM Items CROSS JOIN Stores Inner Join Item_Group On Items.GroupID = Item_Group.Group_ID
	Where
			Items.Item_ID = IsNull(@ItemID,Items.Item_ID)
		And Stores.Store_ID = IsNull(@StoreID,Stores.Store_ID)
		And Items.GroupID = IsNull(@GroupID,Items.GroupID)
		And Item_Group.K_GroupID = IsNull(@KGroupID,Item_Group.K_GroupID)
	
	
	
	
------------------------------- نتائج الاستعلام  ---------------------------
If @RepType = 0  --*** ارصدة الاصناف اجمالي ***--
	Begin
		Select 
			Item_Group.GroupName,
			Result.MyItem As ItemID,
			Items.ItemCode,
			Items.ItemName,
			Units.UnitName  As MyUnit,
			Sum(QtyAll) Bal,
			dbo.Get_Item_Cost(MyItem,@Pricing,@Date2) As Cost
		From #Result As Result 
			Inner join Items On Result.MyItem = Items.Item_ID
			Inner join Item_Group On Items.GroupID = Item_Group.Group_ID
			Left join Units On Items.UnitID = Units.Unit_ID
		Where
			Items.IsService=0
		Group By
			Item_Group.Group_ID,
			Item_Group.GroupName,
			Result.MyItem,
			Items.ItemCode,
			Items.ItemName,
			Units.UnitName
		Having 
			Case When @HideZero = 0 Or (@HideZero = 1 And Sum(QtyAll)<>0) Then 1 Else 0 End = 1 
		Order By Case @SortBy When 0 Then Result.MyItem When 2 Then Item_Group.Group_ID End ,Case @SortBy When 1 Then ItemName End
	End
	
Else If @RepType = 1 --*** ارصدة الاصناف بالوحدات ***--
	Begin
		Select 
			Item_Group.GroupName,
			Result.MyItem As ItemID,
			Items.ItemCode,
			Items.ItemName,
			Units.UnitName SmallUnit,
			Sum(QtyAll) Bal,
			dbo.Get_Item_Cost(MyItem,@Pricing,@Date2) As Cost,
			Case When Unit2Qty <> 0 Then Cast(Sum(QtyAll)/Unit2Qty As Int) Else 0 End QtyObwa,
			Case When Unit2Qty <> 0 Then BigUnit.UnitName + N'×' + Cast(Unit2Qty As Nvarchar(10)) Else N'' End As BigUnit,
			Sum(QtyAll) - (Case When Unit2Qty <> 0 Then Cast(Sum(QtyAll)/Unit2Qty As Int) *Unit2Qty Else 0 End) As QtyOne
		From #Result As Result 
			Inner join Items On Result.MyItem = Items.Item_ID
			Inner join Item_Group On Items.GroupID = Item_Group.Group_ID
			Left join Units On Items.UnitID = Units.Unit_ID
			Left join Units As BigUnit On Items.Unit2 = BigUnit.Unit_ID
		Where 
			Items.IsService=0
		Group By
			Item_Group.Group_ID,
			Item_Group.GroupName,
			Result.MyItem,
			Items.ItemCode,
			Items.ItemName,
			Units.UnitName,
			BigUnit.UnitName,
			Items.Unit2Qty
		Having 
			Case When @HideZero = 0 Or (@HideZero = 1 And Sum(QtyAll)<>0) Then 1 Else 0 End = 1
		Order By Case @SortBy When 0 Then Result.MyItem When 2 Then Item_Group.Group_ID End ,Case @SortBy When 1 Then ItemName End
	End

Else If @RepType = 2  --*** ارصدة المخازن مجمعة ***--
	Begin
		Declare @Store1 As Nvarchar(50) ,@Store2 As Nvarchar(50) ,@Store3 As Nvarchar(50) ,@Store4 As Nvarchar(50) ,@Store5 As Nvarchar(50), 
				@Store6 As Nvarchar(50) ,@Store7 As Nvarchar(50) ,@Store8 As Nvarchar(50) ,@Store9 As Nvarchar(50) ,@Store10 As Nvarchar(50) 

		Declare @MyStore Int =-2,@Id SmallInt =1,@StoreName As Nvarchar(50)

		While @Id <=10 
			Begin
				If @MyStore<>-1 Set @MyStore =IsNULL((Select Min(MyStore) From #Result Where MyStore>@MyStore ),-1)
				Set @StoreName =IsNUll((Select StoreName From Stores Where Store_ID=@MyStore),'-')
				If @ID=1 Set @Store1=@StoreName
				If @ID=2 Set @Store2=@StoreName
				If @ID=3 Set @Store3=@StoreName
				If @ID=4 Set @Store4=@StoreName
				If @ID=5 Set @Store5=@StoreName
				If @ID=6 Set @Store6=@StoreName
				If @ID=7 Set @Store7=@StoreName
				If @ID=8 Set @Store8=@StoreName
				If @ID=9 Set @Store9=@StoreName
				If @ID=10 Set @Store10=@StoreName
				Set @StoreName ='-'
				Set @Id = @ID+1
			End

			Select 
				Item_Group.GroupName,
				Result.MyItem As ItemID,
				Items.ItemCode,
				Items.ItemName,
				Units.UnitName As MyUnit,
				Sum(QtyAll) Bal,
				dbo.Get_Item_Cost(MyItem,@Pricing,@Date2) As Cost,
				Sum(Case When Stores.StoreName = @Store1 Then QtyAll Else 0 End) As Store1,
				Sum(Case When Stores.StoreName = @Store2 Then QtyAll Else 0 End) As Store2,
				Sum(Case When Stores.StoreName = @Store3 Then QtyAll Else 0 End) As Store3,
				Sum(Case When Stores.StoreName = @Store4 Then QtyAll Else 0 End) As Store4,
				Sum(Case When Stores.StoreName = @Store5 Then QtyAll Else 0 End) As Store5,
				Sum(Case When Stores.StoreName = @Store6 Then QtyAll Else 0 End) As Store6,
				Sum(Case When Stores.StoreName = @Store7 Then QtyAll Else 0 End) As Store7,
				Sum(Case When Stores.StoreName = @Store8 Then QtyAll Else 0 End) As Store8,
				Sum(Case When Stores.StoreName = @Store9 Then QtyAll Else 0 End) As Store9,
				Sum(Case When Stores.StoreName = @Store10 Then QtyAll Else 0 End) As Store10
			From #Result As Result 
				Inner join Items On Result.MyItem = Items.Item_ID
				Inner join Item_Group On Items.GroupID = Item_Group.Group_ID
				Left join Stores On Result.MyStore = Stores.Store_ID
				Left join Units On Items.UnitID = Units.Unit_ID
			Where 
				Items.IsService=0
			Group By
				Item_Group.Group_ID,
				Item_Group.GroupName,
				Result.MyItem,
				Items.ItemCode,
				Items.ItemName,
				Units.UnitName
			Having  
				Case When @HideZero = 0 Or (@HideZero = 1 And Sum(QtyAll)<>0) Then 1 Else 0 End = 1
			Order By Case @SortBy When 0 Then Result.MyItem When 2 Then Item_Group.Group_ID End ,Case @SortBy When 1 Then ItemName End

			Select @Store1,@Store2,@Store3,@Store4,@Store5,@Store6,@Store7,@Store8,@Store9,@Store10
		End

Else If @RepType = 3  --*** ارصدة الاصناف بالصور ***--
	Begin
		Select 
			Item_Group.GroupName,
			Result.MyItem As ItemID,
			Items.ItemCode,
			Items.ItemName,
			Units.UnitName As MyUnit,
			Sum(QtyAll) Bal,
			dbo.Get_Item_Cost(MyItem,@Pricing,@Date2) As Cost,
			--(Select Photo From Items Where Item_ID=Result.MyItem) As Photo
			Case When Items.IsPhoto=1 Then @FolderPath + N'\' + Cast(Result.MyItem As nvarchar(20)) +  N'.Png' Else N'' End As PhotoPath
		From #Result As Result 
			Inner join Items On Result.MyItem = Items.Item_ID
			Inner join Item_Group On Items.GroupID = Item_Group.Group_ID
			Left join Units On Items.UnitID = Units.Unit_ID
		Where 
			Items.IsService=0
		Group By
			Item_Group.Group_ID,
			Item_Group.GroupName,
			Result.MyItem,
			Items.ItemCode,
			Items.ItemName,
			Units.UnitName,
			Items.IsPhoto
		Having 
			Case When @HideZero = 0 Or (@HideZero = 1 And Sum(QtyAll)<>0) Then 1 Else 0 End = 1
		Order By Case @SortBy When 0 Then Result.MyItem When 2 Then Item_Group.Group_ID End ,Case @SortBy When 1 Then ItemName End
	End
    
Else If @RepType = 4  --*** ارصدة الاصناف بالمخازن لاقفال السنة ***--
	Begin
		Select 
			Result.MyStore,
			Result.MyItem,
			Sum(QtyAll) Bal,
			dbo.Get_Item_Cost(MyItem,@Pricing,@Date2) As Cost
		From #Result As Result Join Items On Result.MyItem = Items.Item_ID
		Where
			Items.IsService=0
		Group By
			Result.MyStore,
			Result.MyItem
		Having 
			Case When @HideZero = 0 Or (@HideZero = 1 And Sum(QtyAll)<>0) Then 1 Else 0 End = 1 
		Order By 
			Result.MyStore,
			Result.MyItem
	End

	IF OBJECT_ID('tempdb..#Result') IS NOT NULL DROP TABLE #Result;
END
GO

ALTER PROCEDURE [dbo].[Insert-Users]
@User_ID int,
@UserName nvarchar(30),
@UserPass nvarchar(30),
@MyDate datetime = N'2000-01-01',
@MyUser nvarchar(100),
@Active Bit,
@BranID int,
@StoreID int,
@CashID int,
@IsAllBran Bit,
@IsStock Bit,
@IsMan Bit,
@ManID Int,
@IsProfet Bit,
@IsCost Bit,
@IsPrice0 Bit,
@IsPrice1 Bit,
@IsPrice2 Bit,
@IsPrice3 Bit,
@IsPrice4 Bit,
@IsPriceAvrg Bit,
@UpdateCost Bit,
@IsCloseAcc Bit,
@IsCusLimit Bit,
@IsPriceEdit Bit,
@IsInvDisc Bit,
@IsInvAddMony Bit,
@IsMaxDisc Bit,
@IsMaxQty Bit,
@IsMaxPrice Bit,
@IsMultiCash Bit,
@IsCashBal Bit,
@IsTaskAvrg Bit,
@Price0_Name Nvarchar(15),
@Price1_Name Nvarchar(15),
@Price2_Name Nvarchar(15),
@Price3_Name Nvarchar(15),
@Price4_Name Nvarchar(15),
@Avrg_Name Nvarchar(15),
@RecordID Int

AS 

Begin
	SET NOCOUNT ON;
	Set @MyUser =  Replace(@MyUser,'#Now#',FORMAT(GETDATE(), 'dd-MM-yyyy hh:mm:ss tt'))

	If @User_ID Is NULL Set @User_ID = IsNULL((Select Max([User_ID]) From Users Where [User_ID] <> 808 ),0)+1
	If @User_ID = 808 Set @User_ID = 809
	insert into Users (
			[User_ID],
			UserName,
			UserPass,
			MyDate,
			MyUser,
			UserEdit,
			Active,
			BranID,
			StoreID,
			CashID,
			IsAllBran,
			IsStock,
			IsMan,
			ManID,
			IsProfet,
			IsCost,
			IsPrice0,
			IsPrice1,
			IsPrice2,
			IsPrice3,
			IsPrice4,
			IsPriceAvrg,
			UpdateCost,
			IsCloseAcc,
			IsCusLimit,
			IsPriceEdit,
			IsInvDisc,
			IsMaxDisc,
			IsInvAddMony,
			IsMaxQty,
			IsMaxPrice,
			IsMultiCash,
			IsCashBal,
			IsTaskAvrg,
			Price0_Name,
			Price1_Name,
			Price2_Name,
			Price3_Name,
			Price4_Name,
			Avrg_Name,
			IsBarcode)
		
		Values(
			@User_Id,
			@UserName,
			@UserPass,
			@MyDate,
			@MyUser,
			NULL,
			@Active,
			@BranID,
			@StoreID,
			@CashID,
			@IsAllBran ,
			@IsStock ,
			@IsMan ,
			@ManID ,
			@IsProfet ,
			@IsCost ,
			@IsPrice0 ,
			@IsPrice1 ,
			@IsPrice2 ,
			@IsPrice3 ,
			@IsPrice4 ,
			@IsPriceAvrg,
			@UpdateCost,
			@IsCloseAcc,
			@IsCusLimit,
			@IsPriceEdit,
			@IsInvDisc,
			@IsMaxDisc,
			@IsInvAddMony,
			@IsMaxQty,
			@IsMaxPrice,
			@IsMultiCash,
			@IsCashBal,
			@IsTaskAvrg,
			@Price0_Name,
			@Price1_Name,
			@Price2_Name,
			@Price3_Name,
			@Price4_Name,
			@Avrg_Name,
			0 )

	Select @User_Id 
End


GO

ALTER PROCEDURE [dbo].[Update-Setting] 
@User_ID int,
@Buy_Size tinyint,
@Sales_Size tinyint,
@Ezn_Size tinyint,
@Cash_Size tinyint,
@Casher_Printer nvarchar(100),
@Casher_Paper nvarchar(100),
@IsSumQty bit,
@IsPagePlace bit,
@Hide_Tafreda bit,
@Hide_Iqrar bit,
@Hide_Code bit,
@Hide_Unit bit,
@Hide_Man bit,
@Hide_Disc bit,
@IsBeforDisc bit,
@Hide_User bit,
@Hide_Store bit,
@IsOldBalSales bit,
@IsOldBalBuy bit,
@IsPreview bit,
@InvName nvarchar(20),
@SortBy tinyint,
@IsCeramic Bit,
@CusIns_Alarm bit,
@CusIns_Days tinyint,
@CusShek_Alarm bit,
@CusShek_Days tinyint,
@SuppShek_Alarm bit,
@SuppShek_Days tinyint,
@Limit_Alarm bit,
@IsDiscPer bit,
@IsBarcode bit,
@HideCom bit,
@PassOnDel Bit,
@IsColor Bit,
@FindCode Bit,
@FindBar Bit,
@NoUnitTab Bit,
@IsUnit2 Bit,
@IsSignLogo Bit,
@IsAutoSave Bit,
@IsCashPay Bit,
@IsLimitPrint Bit,
@IsPayShek Bit,
@AddName Nvarchar(10),
@DecNo smallint

AS 

Begin

	Update Users SET 
      [Buy_Size]  = @Buy_Size,
      [Sales_Size]  = @Sales_Size,
      [Ezn_Size]  = @Ezn_Size,
      [Cash_Size]  = @Cash_Size,
      [Casher_Printer]  = @Casher_Printer,
	  [Casher_Paper]  = @Casher_Paper,
      [IsSumQty]  = @IsSumQty,
      [IsPagePlace]  = @IsPagePlace,
      [Hide_Tafreda]  = @Hide_Tafreda,
      [Hide_Iqrar]  = @Hide_Iqrar,
      [Hide_Code]  = @Hide_Code,
      [Hide_Unit]  = @Hide_Unit,
      [Hide_Man]  = @Hide_Man,
      [Hide_Disc]  = @Hide_Disc,
	  [IsBeforDisc] = @IsBeforDisc,
      [Hide_User]  = @Hide_User,
	  [Hide_Store] = @Hide_Store,
      [IsOldBalSales]  = @IsOldBalSales,
      [IsOldBalBuy]  = @IsOldBalBuy,
      [IsPreview]  = @IsPreview,
      [InvName]  = @InvName,
      [SortBy]  = @SortBy,
	  [IsCeramic] = @IsCeramic,
      [CusIns_Alarm]  = @CusIns_Alarm,
      [CusIns_Days]  = @CusIns_Days,
      [CusShek_Alarm]  = @CusShek_Alarm,
      [CusShek_Days]  = @CusShek_Days,
      [SuppShek_Alarm]  = @SuppShek_Alarm,
      [SuppShek_Days]  = @SuppShek_Days,
      [Limit_Alarm]  = @Limit_Alarm,
      [IsDiscPer]  = @IsDiscPer,
      [IsBarcode]  = @IsBarcode,
	  [HideCom] = @HideCom,
	  [PassOnDel] = @PassOnDel,
	  [IsColor] = @IsColor,
	  [FindCode]= @FindCode,
	  [FindBar]= @FindBar,
	  [NoUnitTab] = @NoUnitTab,
	  [IsUnit2] = @IsUnit2,
	  [IsSignLogo] = @IsSignLogo,
	  [IsAutoSave] = @IsAutoSave,
	  [IsCashPay] = @IsCashPay,
	  [IsLimitPrint] = @IsLimitPrint,
	  [IsPayShek] = @IsPayShek,
	  [AddName] = @AddName,
      [DecNo]  = @DecNo
	Where
		[User_Id]=@User_Id 
End


GO

ALTER PROCEDURE [dbo].[Update-Users] 
@User_ID int,
@UserName nvarchar(30),
@UserPass nvarchar(30),
@MyDate datetime = N'2000-01-01',
@MyUser nvarchar(100),
@Active Bit,
@BranID Int,
@StoreID int,
@CashID int,
@IsAllBran Bit,
@IsStock Bit,
@IsMan Bit,
@ManID Int,
@IsProfet Bit,
@IsCost Bit,
@IsPrice0 Bit,
@IsPrice1 Bit,
@IsPrice2 Bit,
@IsPrice3 Bit,
@IsPrice4 Bit,
@IsPriceAvrg Bit,
@UpdateCost Bit,
@IsCloseAcc Bit,
@IsCusLimit Bit,
@IsPriceEdit Bit,
@IsInvDisc Bit,
@IsMaxDisc Bit,
@IsInvAddMony Bit,
@IsMaxQty Bit,
@IsMaxPrice Bit,
@IsMultiCash Bit,
@IsCashBal Bit,
@IsTaskAvrg Bit,
@Price0_Name Nvarchar(15),
@Price1_Name Nvarchar(15),
@Price2_Name Nvarchar(15),
@Price3_Name Nvarchar(15),
@Price4_Name Nvarchar(15),
@Avrg_Name Nvarchar(15),
@RecordID Int

AS 

Begin
	SET NOCOUNT ON;
	Set @MyUser =  Replace(@MyUser,'#Now#',FORMAT(GETDATE(), 'dd-MM-yyyy hh:mm:ss tt'))

	If @User_ID Is NULL Set @User_ID = IsNULL((Select Max([User_ID]) From Users Where [User_ID] <> 808 ),0)+1
	If @User_ID = 808 Set @User_ID = 809
	Begin TRY
		BEGIN TRAN
			Update Users SET 
				[User_ID] = @User_ID,
				UserName = @UserName,
				UserPass = @UserPass, 
				Active = @Active, 
				BranID = @BranID,
				StoreID = @StoreID, 
				CashID = @CashID, 
				IsAllBran = @IsAllBran,
				IsStock = @IsStock,
				IsMan = @IsMan,
				ManID = @ManID,
				IsProfet = @IsProfet,
				IsCost = @IsCost,
				IsPrice0 = @IsPrice0,
				IsPrice1 = @IsPrice1,
				IsPrice2 = @IsPrice2,
				IsPrice3 = @IsPrice3,
				IsPrice4 = @IsPrice4,
				IsPriceAvrg = @IsPriceAvrg,
				UpdateCost = @UpdateCost,
				IsCloseAcc = @IsCloseAcc,
				IsCusLimit = @IsCusLimit,
				IsPriceEdit = @IsPriceEdit,
				IsInvDisc = @IsInvDisc,
				IsMaxDisc = @IsMaxDisc,
				IsInvAddMony = @IsInvAddMony,
				IsMaxQty = @IsMaxQty,
				IsMaxPrice = @IsMaxPrice,
				IsMultiCash = @IsMultiCash,
				IsCashBal = @IsCashBal,
				IsTaskAvrg = @IsTaskAvrg,
				Price0_Name = @Price0_Name,
				Price1_Name = @Price1_Name,
				Price2_Name = @Price2_Name,
				Price3_Name = @Price3_Name,
				Price4_Name = @Price4_Name,
				Avrg_Name = @Avrg_Name,
				UserEdit=@MyUser
			Where
				[User_Id]=@RecordID 

			If @RecordID <> @User_ID ---- اذا كان كود المستخدم اتغير هيتم تغييره في جداول الاستيراد ----
				Begin
					Update Import_Invoice Set 
						AddUser = Case When AddUser=@RecordID Then @User_ID Else AddUser End,
						EditUser = Case When EditUser=@RecordID Then @User_ID Else EditUser End
					Where AddUser=@RecordID Or EditUser=@RecordID

					Update Import_Exp Set 
						AddUser = Case When AddUser=@RecordID Then @User_ID Else AddUser End,
						EditUser = Case When EditUser=@RecordID Then @User_ID Else EditUser End
					Where AddUser=@RecordID Or EditUser=@RecordID

					Update Import_Payed Set 
						AddUser = Case When AddUser=@RecordID Then @User_ID Else AddUser End,
						EditUser = Case When EditUser=@RecordID Then @User_ID Else EditUser End
					Where AddUser=@RecordID Or EditUser=@RecordID

					Update Import_Expenses Set 
						AddUser = Case When AddUser=@RecordID Then @User_ID Else AddUser End,
						EditUser = Case When EditUser=@RecordID Then @User_ID Else EditUser End
					Where AddUser=@RecordID Or EditUser=@RecordID
	
					Update Omla Set 
						AddUser = Case When AddUser=@RecordID Then @User_ID Else AddUser End,
						EditUser = Case When EditUser=@RecordID Then @User_ID Else EditUser End
					Where AddUser=@RecordID Or EditUser=@RecordID
				End

				Select @User_Id 

			COMMIT TRAN
		End TRY

		BEGIN CATCH
			IF(@@TRANCOUNT > 0)
			ROLLBACK TRAN;
			THROW; -- raise error to the client
		END CATCH
End


GO

ALTER Procedure [dbo].[Insert-Company]
 @NameAr Nvarchar(150), 
 @NameEn Nvarchar(150), 
 @AdressAr Nvarchar(250), 
 @AdressEn Nvarchar(250), 
 @Tel Nvarchar(200), 
 @Whatsapp Nvarchar(100),  
 @Facebook Nvarchar(150), 
 @Website Nvarchar(150), 
 @Segl Nvarchar(50), 
 @Dariba Nvarchar(50),
 @CurMain Nvarchar(10),
 @CurSub Nvarchar(10),
 @Logo Image

  As

Begin
	Update Company Set 
		NameAr = @NameAr, 
		NameEn = @NameEn, 
		AdressAr = @AdressAr, 
		AdressEn = @AdressEn, 
		Tel = @Tel, 
		Whatsapp = @Whatsapp, 
		Facebook = @Facebook, 
		Website = @Website, 
		Segl = @Segl, 
		Dariba = @Dariba,
		CurMain = @CurMain,
		CurSub = @CurSub,
		Logo = @Logo
	Where ID= 0
End


GO

ALTER PROCEDURE [dbo].[Proc_Import_Invoice]
@Inv_ID int,
@InvName Nvarchar(100),
@SuppID int,
@InvDate date,
@MadeIn Nvarchar(20),
@InvType Nvarchar(10),
@ShipPort Nvarchar(30),
@InvTotal Float,
@OmlaID Tinyint,
@OmlaRate Decimal(8,4),
@ExpTotal float,
@FrokOmla Float,
@Notes nvarchar(250),
@MyUser int,
@MyPC nvarchar(30),
@Proc TinyInt

AS 
Begin
	SET NOCOUNT ON;
	
	IF @Proc = 2         --Delete-- 
		Begin
			Begin TRY
				BEGIN TRAN
					Declare @IsTaskAvrg Bit = IsNULL((Select IsTaskAvrg From Users Where [User_ID]=@MyUser),0)
					--=========================================== الاصناف  ===================================--
					Declare @ItemID Int =IsNULL((Select Min(ItemID) From Import_Items Where InvID=@Inv_ID),-1)
					Declare @MyInvDate DateTime =IsNUll((Select InvDate From Import_Invoice Where Inv_ID = @Inv_ID),GetDate())
					While @ItemID > -1
						Begin
							Delete From Import_Items Where InvID=@Inv_ID And ItemID=@ItemID
							Exec dbo.Set_Item_Stock @ItemID,@MyInvDate,@IsTaskAvrg --- تحديث رصيد الصنف ---
							Set @ItemID  =IsNULL((Select Min(ItemID) From Import_Items Where InvID=@Inv_ID And ItemID>@ItemID),-1)
						End

						--=========================================== الخزائن  ===================================--
						Declare @CashID Int = IsNULL((Select Min(CashID) From (Select CashID From Import_Exp Where InvID=@Inv_ID Union All Select CashID From Import_Payed Where InvID=@Inv_ID) As TblCash),-1)
						While @CashID > -1
								Begin
									Delete From Import_Exp Where InvID=@Inv_ID And CashID=@CashID
									Delete From Import_Payed Where InvID=@Inv_ID And CashID=@CashID
									Exec dbo.Set_Cash_Balance @CashID --- حساب رصيد الخزينة ---
									Set @CashID = IsNULL((Select Min(CashID) From (Select CashID From Import_Exp Where InvID=@Inv_ID Union All Select CashID From Import_Payed Where InvID=@Inv_ID) As TblCash Where CashID>@CashID),-1)
								End

						--=========================================== المورد  ===================================--
						Set @SuppID = IsNULL((Select SuppID From Import_Invoice Where Inv_ID=@Inv_ID),-1)
						Delete From Import_Invoice Where Inv_ID = @Inv_ID
						Exec dbo.Set_Cus_Balance @SuppID   --- حساب رصيد المورد ---
				COMMIT TRAN
			End TRY

			BEGIN CATCH
					IF(@@TRANCOUNT > 0)
				ROLLBACK TRAN;
				THROW; -- raise error to the client
			END CATCH

		End
		--====================================== End Delete ============================================


	Else IF @Proc = 1         --Update-- 
		Begin
			Declare @OldSupp Int = IsNULL((Select SuppID From Import_Invoice Where Inv_ID=@Inv_ID And SuppID <> @SuppID),-1)
			Update Import_Invoice SET 
				 InvName = @InvName
				,SuppID = @SuppID
				,InvDate = @InvDate
				,MadeIn = @MadeIn
				,InvType = @InvType
				,ShipPort = @ShipPort
				,InvTotal = @InvTotal
				,OmlaID = @OmlaID
				,OmlaRate = @OmlaRate
				,ExpTotal = @ExpTotal
				,FrokOmla = @FrokOmla
				,Notes = @Notes
				,EditUser = @MyUser
				,EditDate = GETDATE()
				,EditPC = @MyPC
			Where 
				Inv_ID = @Inv_ID
		End
		--====================================== End Update ============================================
	
	
	Else  --Proc=0--     --Insert--
		Begin
			If @Inv_ID Is NULL Set @Inv_ID = IsNULL((Select Max(Inv_ID) From Import_Invoice),0)+1

			insert into Import_Invoice (Inv_ID,InvName,SuppID,InvDate,MadeIn,InvType,ShipPort,InvTotal,OmlaID,OmlaRate,ExpTotal,FrokOmla,Notes,AddUser,AddDate,AddPC)
			Values	(@Inv_ID,@InvName,@SuppID,@InvDate,@MadeIn,@InvType,@ShipPort,@InvTotal,@OmlaID,@OmlaRate,@ExpTotal,@FrokOmla,@Notes,@MyUser,GetDate(),@MyPC)
		End
		--====================================== End Insert ============================================

	Exec dbo.Set_Cus_Balance @SuppID   --- حساب رصيد المورد ---
	if @OldSupp <> -1 Exec dbo.Set_Cus_Balance @OldSupp   --- حساب رصيد المورد القديم---
	
	Select @Inv_ID
End

GO

Update Company Set VersionDate=N'25.12.2025.001'
GO
