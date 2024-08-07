using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Boat
{
    public class Player
    {
        public Vector2 Position { get; private set; }
        public Texture2D Texture { get; private set; }
        public CollisionBox CollisionBox { get; private set; }
        private float _speed; // 角色移动速度
        private float Pwidth = 1.15f;
        private float Pheight = 0.5f;

        // 设置纹理宽度和高度为变量
        private int _textureWidth;
        private int _textureHeight;

        public Player(Texture2D texture, GraphicsDevice graphicsDevice)
        {
            Texture = texture;
            Position = new Vector2(100, 100);
            _speed = 2 * texture.Width;

            // 初始化纹理宽度和高度
            _textureWidth = Texture.Width*14/30;
            _textureHeight = Texture.Height*4/5;

            CollisionBox = new CollisionBox(graphicsDevice, Position, new Vector2(_textureWidth, _textureHeight), Pwidth, Pheight);
        }

        public void Update(GameTime gameTime, CollisionBox[] obstacles)
        {
            KeyboardState state = Keyboard.GetState();

            float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds; // 获取时间增量
            Vector2 newPosition = Position;

            // 使用 WASD 键控制玩家移动，乘以 deltaTime 和速度变量
            if (state.IsKeyDown(Keys.W))
            {
                newPosition.Y -= _speed * deltaTime;
            }
            if (state.IsKeyDown(Keys.S))
            {
                newPosition.Y += _speed * deltaTime;
            }
            if (state.IsKeyDown(Keys.A))
            {
                newPosition.X -= _speed * deltaTime;
            }
            if (state.IsKeyDown(Keys.D))
            {
                newPosition.X += _speed * deltaTime;
            }

            CollisionBox.UpdatePosition(newPosition, new Vector2(_textureWidth, _textureHeight), Pwidth, Pheight);

            // 检查与障碍物的碰撞
            foreach (var obstacle in obstacles)
            {
                if (CollisionBox.Intersects(obstacle))
                {
                    // 碰撞时重置为原来的位置
                    CollisionBox.UpdatePosition(Position, new Vector2(_textureWidth, _textureHeight), Pwidth, Pheight);
                    return;
                }
            }

            // 更新位置
            Position = newPosition;
            CollisionBox.UpdatePosition(Position, new Vector2(_textureWidth, _textureHeight), Pwidth, Pheight); // 更新碰撞箱位置
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            TextureManager.DrawTexture(spriteBatch, Texture, Position, Color.White);
            CollisionBox.Draw(spriteBatch); // 绘制碰撞箱
        }
    }
}