create database tuyensinh;
use tuyensinh;

create table chitietdt(
dtduthi int primary key,
diengiaidt nvarchar(45),
diemut int
);

create table danhsach(
sobd int primary key,
ho nvarchar(45),
ten nvarchar(45),
phai boolean,
ntns date,
dtduthi int
);

create table diemthi(
sobd int primary key,
toan int,
van int,
anh int,
foreign key (sobd) references danhsach(sobd)
);

create view hotens as
select concat(ho," ",ten) as hoten, sobd from danhsach;

create view diemtong as
select sum(toan+van+anh+diemut) as tongdiem,danhsach.sobd from danhsach
join diemthi on danhsach.sobd = diemthi.sobd
join chitietdt on danhsach.dtduthi = chitietdt.dtduthi
group by diemthi.sobd;

create view xeploai as 
select (case when tongdiem >= 24 and toan >=7 and van >=7 and anh >=7 then "gioi"
 when tongdiem >= 21 and toan >=6 and van >=6 and anh >=6 then "kha"
 when tongdiem >= 15 and toan >=4 and van >=4 and anh >=4 then "trung binh" else 'truot' end) as xeploai,diemthi.sobd from diemtong
join diemthi on diemtong.sobd = diemthi.sobd
group by diemthi.sobd;

select timestampdiff(year,ntns,Curdate()) as tuoi from danhsach;

create view ket_qua as
select hoten,phai,timestampdiff(year,ntns,curdate()) as tuoi,toan,van,anh,tongdiem,xeploai,danhsach.dtduthi from danhsach
join hotens on hotens.sobd = danhsach.sobd
join diemtong on diemtong.sobd = danhsach.sobd
join xeploai on xeploai.sobd = danhsach.sobd
join diemthi on diemthi.sobd = danhsach.sobd
join chitietdt on chitietdt.dtduthi = danhsach.dtduthi;

create view gioi as
select danhsach.sobd,hoten,toan,van,anh,tongdiem,diengiaidt from danhsach
join hotens on hotens.sobd = danhsach.sobd
join diemtong on diemtong.sobd = danhsach.sobd
join diemthi on diemthi.sobd = danhsach.sobd
join chitietdt on chitietdt.dtduthi = danhsach.dtduthi
where tongdiem >= 25 and (toan = 10 or van = 10 or anh = 10);

create view dau as
select hoten,phai,timestampdiff(year,ntns,curdate()) as tuoi,toan,van,anh,tongdiem,xeploai,danhsach.dtduthi  from danhsach
join hotens on hotens.sobd = danhsach.sobd
join diemtong on diemtong.sobd = danhsach.sobd
join xeploai on xeploai.sobd = danhsach.sobd
join diemthi on diemthi.sobd = danhsach.sobd
join chitietdt on chitietdt.dtduthi = danhsach.dtduthi
where xeploai not in ("truot");

create view thukhoa as
select hoten,phai,timestampdiff(year,ntns,curdate()) as tuoi,toan,van,anh,tongdiem,xeploai,danhsach.dtduthi  from danhsach
join hotens on hotens.sobd = danhsach.sobd
join diemtong on diemtong.sobd = danhsach.sobd
join xeploai on xeploai.sobd = danhsach.sobd
join diemthi on diemthi.sobd = danhsach.sobd
join chitietdt on chitietdt.dtduthi = danhsach.dtduthi
where tongdiem >= (select max(tongdiem) from (select tongdiem from diemtong) as t);

delimiter //
create procedure getdiem(in sobd int, out toan int, out van int, out anh int, out diemut int, out tongdiem int)
begin
select diemthi.toan into toan from diemthi
where diemthi.sobd = sobd;

select diemthi.van into van from diemthi
where diemthi.sobd = sobd;

select diemthi.anh into anh from diemthi
where diemthi.sobd = sobd;

select chitietdt.diemut into diemut from chitietdt
join danhsach on danhsach.dtduthi = chitietdt.dtduthi
where danhsach.sobd = sobd;

select diemtong.tongdiem into tongdiem from diemtong
where diemtong.sobd = sobd;
end;
//

call getdiem (3,@toan,@van,@anh,@diemut,@tongdiem);
select @toan,@van,@anh,@diemut,@tongdiem;

delimiter //
create trigger danhsachdt
before insert
on danhsach
for each row
begin
if new.dtduthi not in (select dtduthi from chitietdt) 
then signal sqlstate'45000'
set message_text = 'dtduthi khong ton tai';
end if;
end;
//

drop trigger if exists autoupdate;
delimiter //
create trigger autoupdate
before insert
on diemthi
for each row
begin
set new.diemuutien = (select diemut from chitietdt join danhsach
on danhsach.dtduthi = chitietdt.dtduthi and danhsach.sobd = new.sobd);
set new.tongdiem = new.toan+new.van+new.anh+new.diemuutien;
end;
//

delimiter //
create trigger autodelete
after delete
on danhsach
for each row
begin
delete from diemthi where diemthi.sobd = old.sobd;
end;
//

insert into diemthi (sobd,toan,van,anh)
value (1,8.0,8.0,8.0);