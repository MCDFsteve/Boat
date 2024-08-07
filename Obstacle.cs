//障碍物-岩石
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boat
{
    public class Obstacle
    {
        public Vector2 Position { get; private set; }
        public Texture2D Texture { get; private set; }
        public CollisionBox CollisionBox { get; private set; }

        public Obstacle(Texture2D texture, Vector2 position, GraphicsDevice graphicsDevice)
        {
            Texture = texture;
            Position = position;
            CollisionBox = new CollisionBox(graphicsDevice, position, new Vector2(texture.Width, texture.Height), 0, 0);
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            TextureManager.DrawTexture(spriteBatch, Texture, Position, Color.White);
            CollisionBox.Draw(spriteBatch); // 绘制碰撞箱
        }
    }
}