enum Rol { administrador, recepcionista, socio }

Rol rolFromString(String s) {
  switch (s) {
    case 'administrador': return Rol.administrador;
    case 'socio':         return Rol.socio;
    default:              return Rol.recepcionista;
  }
}

class UsuarioSesion {
  final int      idUsuario;
  final String   nombre;
  final String   correo;
  final Rol      rol;
  final int?     idSocio; // solo aplica cuando rol == socio
  final String   token;   // JWT devuelto por el backend
  String?        fotoUrl; // mutable: se actualiza al subir una nueva foto

  UsuarioSesion({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.token,
    this.idSocio,
    this.fotoUrl,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> usuario, String token) {
    return UsuarioSesion(
      idUsuario: usuario['id_usuario'] as int,
      nombre:    usuario['nombre']     as String,
      correo:    usuario['correo']     as String,
      rol:       rolFromString(usuario['rol'] as String),
      idSocio:   usuario['id_socio']   as int?,
      token:     token,
      fotoUrl:   usuario['foto_url']   as String?,
    );
  }

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
  String get rolLabel {
    switch (rol) {
      case Rol.administrador: return 'Administrador';
      case Rol.recepcionista: return 'Recepcionista';
      case Rol.socio:         return 'Socio';
    }
  }
}
