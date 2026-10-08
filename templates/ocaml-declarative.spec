# Read through the Fedora OCaml packaging guidelines and make sure you don't miss anything!
# https://docs.fedoraproject.org/tr/packaging-guidelines/OCaml/

Name:
Version:
Release:        1%{?dist}
Summary:
License:
URL:
Source0:
Packager:
BuildRequires:  ocaml
BuildRequires:  ocaml-dune
Requires:
BuildSystem:    dune

%description

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{evr}

%description    devel
The %{name}-devel package contains libraries and signature files for
developing applications that use %{name}.

%prep
%autosetup

%files -f .ofiles
%license
%doc

%files devel -f .ofiles-devel

%changelog
*
-
