create database if not exists webpygui; 
use webpygui;

create table nodeinfo (
	id int auto_increment,
	hostname text,
	macaddr text,
	ipaddr text,
	primary key (id)
);

create table imageinfo (
	id int auto_increment,
	imagename text,
	imagelocation text,
        kernel text,
        initrd text,
	primary key (id)
);

