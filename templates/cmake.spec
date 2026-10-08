# Read through the Fedora cmake packaging guidelines and make sure you don't miss anything!
# https://docs.fedoraproject.org/tr/packaging-guidelines/CMake/

Name:
Version:
Release:        1%{?dist}
Summary:
License:
URL:
Source0:
Packager:
BuildRequires:	cmake
BuildRequires:	cmake-rpm-macros
Requires:

%description

%prep
%autosetup

%conf
%cmake

%build
%cmake_build

%install
%cmake_install

%check
%ctest

%files
%license
%doc

%changelog
*
-
