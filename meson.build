# Project name, programming language and version
project (
    'com.github.alexkdeveloper.somafm',
    'vala', 'c',
    version: '1.0.0'
)

gnome = import('gnome')
i18n = import ('i18n')

# Project arguments
add_global_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)
add_global_arguments(
    ['--vapidir', meson.current_source_dir() / 'vapi'],
    language: 'vala'
)

conf = configuration_data()
# Get the package data directory under Meson
pkgdatadir = join_paths([ get_option('prefix'),
                          get_option('datadir'),
                          meson.project_name() ])

conf.set_quoted('PKGDATADIR', pkgdatadir)
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

# Other configs
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

# Arguments for C
c_args = [
  '-include', 'config.h',
  '-w'
]

# Arguments for Vala
vala_args = ['--target-glib=2.50', meson.source_root() + '/src/config.vapi']

# Listing dependencies
dependencies = [
    dependency ('gio-2.0'),
    dependency ('gtk4'),
    dependency ('gstreamer-1.0'),
    dependency('libpulse'),
    dependency('libpulse-mainloop-glib')
]

subdir ('src')

# Executable
executable (
    meson.project_name (),
    sources,
    dependencies: dependencies, 
    c_args: c_args, vala_args: vala_args,
    install: true
)

subdir ('data')
subdir('po')

meson.add_install_script ('meson/post_install.py')
