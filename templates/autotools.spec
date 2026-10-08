# Read through the Fedora packaging guidelines and make sure you don't miss anything!
# https://docs.fedoraproject.org/tr/packaging-guidelines/

Name:
Version:
Release:        1%{?dist}
Summary:
License:
URL:
Source0:
Packager:
BuildRequires:  make
BuildRequires:	gcc
Requires:

%description

%prep
%autosetup

%conf
%configure

%build
%make_build

%install
%make_install

%check
%make_build check
# Depends on the project, if there is a check/test target
%make_build test

%files
%license
%doc

%changelog
*
-
