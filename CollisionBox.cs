//碰撞箱
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boat
{
    public class CollisionBox
    {
        private Rectangle _box;
        private Texture2D _borderTexture;

        public CollisionBox(GraphicsDevice graphicsDevice, Vector2 position, Vector2 size, float relativeX, float relativeY)
        {
            // 调整碰撞箱位置和大小
            Vector2 adjustedSize = size * 2; // 将大小调整为两倍
            _box = new Rectangle(
                (position + new Vector2(relativeX * (adjustedSize.X / 2), relativeY * (adjustedSize.Y / 2))).ToPoint(),
                adjustedSize.ToPoint()
            );

            // 创建一个1x1像素的纹理，并设置为黄色
            _borderTexture = new Texture2D(graphicsDevice, 1, 1);
            _borderTexture.SetData(new[] { Color.Yellow });
        }

        public Rectangle Box => _box;

        public void UpdatePosition(Vector2 newPosition, Vector2 size, float relativeX, float relativeY)
        {
            Vector2 adjustedSize = size * 2; // 将大小调整为两倍
            _box.Location = (newPosition + new Vector2(relativeX * (adjustedSize.X / 2), relativeY * (adjustedSize.Y / 2))).ToPoint();
        }

        public bool Intersects(CollisionBox other)
        {
            return _box.Intersects(other.Box);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            // 绘制碰撞箱的黄色描边
            spriteBatch.Draw(_borderTexture, new Rectangle(_box.Left, _box.Top, _box.Width, 1), Color.Yellow); // Top
            spriteBatch.Draw(_borderTexture, new Rectangle(_box.Left, _box.Bottom, _box.Width, 1), Color.Yellow); // Bottom
            spriteBatch.Draw(_borderTexture, new Rectangle(_box.Left, _box.Top, 1, _box.Height), Color.Yellow); // Left
            spriteBatch.Draw(_borderTexture, new Rectangle(_box.Right, _box.Top, 1, _box.Height), Color.Yellow); // Right
        }
    }
}