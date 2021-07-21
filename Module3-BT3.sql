create database Vantai;
use Vantai;

create table trongtai(
matrongtai nvarchar(45) primary key,
trongtaiQD int
);

create table lotrinh(
malotrinh nvarchar(45) primary key,
tenlotrinh nvarchar(45),
dongia int,
thoigianqd int
);

create table chitietvantai(
mavt int auto_increment primary key,
soxe nvarchar(45),
matrongtai nvarchar(45),
malotrinh nvarchar(45),
soluongvt int,
ngaydi datetime,
ngayden datetime,
foreign key (matrongtai) references trongtai(matrongtai),
foreign key (malotrinh) references lotrinh(malotrinh)
);

insert into trongtai
value ('M01', 40);
insert into lotrinh (malotrinh, dongia, thoigianqd)
value ('L02', 500000, 5);
insert into chitietvantai (soxe,matrongtai,malotrinh,soluongvt,ngaydi,ngayden)
value('X03','M01','L01',41,'2019-02-03','2019-02-05');

-- 
create view chitiet as
SELECT soxe,chitietvantai.malotrinh,soluongvt,ngaydi,ngayden,thoigianvt,cuocphi,
    (CASE WHEN thoigianvt > thoigianqd THEN cuocphi / 100 * 5 ELSE 0 END) AS thuong
	FROM chitietvantai
	JOIN lotrinh ON lotrinh.malotrinh = chitietvantai.malotrinh
	JOIN trongtai ON trongtai.matrongtai = chitietvantai.matrongtai
	JOIN (SELECT (CASE WHEN datediff(ngayden, ngaydi) = 0 THEN 1 ELSE datediff(ngayden, ngaydi) END) AS thoigianvt,mavt FROM chitietvantai) AS t on t.mavt = chitietvantai.mavt
	JOIN (SELECT (CASE WHEN soluongvt > trongtaiqd THEN (soluongvt * dongia) / 100 * 105 ELSE soluongvt * dongia END) AS cuocphi,mavt FROM chitietvantai JOIN lotrinh ON lotrinh.malotrinh = chitietvantai.malotrinh JOIN trongtai ON trongtai.matrongtai = chitietvantai.matrongtai) AS k on k.mavt = chitietvantai.mavt;

-- 
create view vuotTT as
select soxe,tenlotrinh,soluongvt,trongtaiqd,ngaydi,ngayden from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
join trongtai on chitietvantai.matrongtai = trongtai.matrongtai
where soluongvt > trongtaiqd

-- 
delimiter //
create procedure getchitiet2(in tenlotrinh nvarchar(45), out soxe varchar(45),out matrongtai int, out soluongvt int, out ngaydi datetime, out ngayden datetime)
begin
select distinct chitietvantai.soxe into soxe from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
where lotrinh.tenlotrinh = tenlotrinh
limit 1;

select distinct chitietvantai.matrongtai into matrongtai from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
where lotrinh.tenlotrinh = tenlotrinh
limit 1;

select distinct chitietvantai.soluongvt into soluongvt from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
where lotrinh.tenlotrinh = tenlotrinh
limit 1;

select distinct chitietvantai.ngaydi into ngaydi from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
where lotrinh.tenlotrinh = tenlotrinh
limit 1;

select distinct chitietvantai.ngayden into ngayden from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
where lotrinh.tenlotrinh = tenlotrinh
limit 1;
end;
//
delimiter //
CREATE PROCEDURE getlotrinh(in soxe nvarchar(45))
begin
select lotrinh.* from chitietvantai
join lotrinh on chitietvantai.malotrinh = lotrinh.malotrinh
where chitietvantai.soxe = soxe;
end
//

call getlotrinh("X01");

call getchitiet("HN > HCM");

call getchitiet2("HN > HCM",@soxe,@matrongtai,@soluongvt,@ngaydi,@ngayden);
select @soxe,@matrongtai,@soluongvt,@ngaydi,@ngayden;

drop trigger if exists thanhtien;
delimiter //
create trigger thanhtien
before insert
on chitietvantai
for each row
begin
set new.thanhtien = new.thanhtien + ( case when new.soluongvt > (select trongtaiqd from trongtai where trongtai.matrongtai = new.matrongtai) then
new.soluongvt * (select dongia from lotrinh where lotrinh.malotrinh = new.malotrinh) * 105/100 else new.soluongvt * (select dongia from lotrinh where lotrinh.malotrinh = new.malotrinh) end);
end;
//

drop procedure if exists getmoney;
delimiter //
create procedure getmoney(in malotrinh nvarchar(45), in nam datetime, out tien int)
begin
select sum(thanhtien) into tien from chitietvantai
where chitietvantai.malotrinh = malotrinh and year(ngayden) = (year(nam))
group by chitietvantai.malotrinh;
end;
//

call getmoney('L01',"2021-01-01",@tien);
select @tien

drop procedure if exists getmoney2;
delimiter //
create procedure getmoney2(in soxe nvarchar(45), in nam datetime, out tien int)
begin
select sum(thanhtien) into tien from chitietvantai
where chitietvantai.soxe = soxe and year(ngayden) = (year(nam))
group by chitietvantai.soxe;
end;
//

call getmoney2('X01',"2021-01-01",@tien);
select @tien