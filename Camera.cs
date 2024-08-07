using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boat
{
    public class Camera
    {
        private Matrix _transform;
        private Vector2 _position;
        private Viewport _viewport;

        public Camera(Viewport viewport)
        {
            _viewport = viewport;
            _transform = Matrix.Identity;
            _position = Vector2.Zero;
        }

        public Matrix Transform => _transform;

        public void Follow(Vector2 targetPosition, Vector2 playerSize)
        {
            _position = targetPosition + playerSize / 2;

            var positionX = _position.X - _viewport.Width / 2;
            var positionY = _position.Y - _viewport.Height / 2;

            _transform = Matrix.CreateTranslation(new Vector3(-positionX, -positionY, 0));
        }

        public void UpdateViewport(Viewport newViewport)
        {
            _viewport = newViewport;
        }
    }
}