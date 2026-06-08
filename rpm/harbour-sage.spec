# harbour-sage.spec
# The "packing recipe." The build tool reads this to wrap our app into a
# single installable file (.rpm) that the phone understands — like zipping
# everything into one box with a label on the outside.

Name:       harbour-sage
Summary:    Private AI chat powered by your own Ollama server
Version:    0.1
Release:    1
License:    MIT
URL:        https://example.com/harbour-sage
Source0:    %{name}-%{version}.tar.bz2

# What this app needs to build...
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
# ...and what it needs to run (Silica = the Sailfish look-and-feel toolkit)
Requires:   sailfishsilica-qt5 >= 0.10.9

%description
Sage is a native Sailfish chat client that talks to a local large language
model served by Ollama over your private network. Your conversations never
leave your own machines.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
