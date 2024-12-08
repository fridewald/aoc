pub type Vector {
  Vector(x: Int, y: Int)
}

pub fn sub(posn1: Vector, posn2: Vector) -> Vector {
  Vector(posn1.x - posn2.x, posn1.y - posn2.y)
}

pub fn add(posn1: Vector, posn2: Vector) -> Vector {
  Vector(posn1.x + posn2.x, posn1.y + posn2.y)
}

pub fn minus(posn1: Vector) -> Vector {
  Vector(-posn1.x, -posn1.y)
}

pub fn multi(posn: Vector, n: Int) -> Vector {
  Vector(n * posn.x, n * posn.y)
}
