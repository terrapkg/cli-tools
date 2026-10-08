# Read through the Fedora meson packaging guidelines and make sure you don't miss anything!
# https://docs.fedoraproject.org/tr/packaging-guidelines/Meson/

Name:
Version:
Release:        1%{?dist}
Summary:
License:
URL:
Source0:
Packager:
BuildRequires:	meson
Requires:

%description

%prep
%autosetup

%conf
%meson

%build
%meson_build

%install
%meson_install

%check
%meson_test

%files
%license
%doc

%changelog
*
-
