using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography; // 用于使用 SHA256
using System.Text; // 用于使用 Encoding
namespace Boat
{
    // Base 类继承自 Game 类并实现 IDisposable 接口
    public class Base : Game, IDisposable
    {
        private GraphicsDeviceManager _graphics; // 管理图形设备的字段
        private SpriteBatch _spriteBatch;        // 批处理绘图的字段
        private bool _disposed = false;          // 标记是否已释放资源
        private Player _player; // 玩家实例
        private Camera _camera; // 摄影机实例
        private DynamicBackground _dynamicBackground; // 动态背景实例
        private DebugOverlay _debugOverlay; // 调试覆盖实例
        private List<Obstacle> _obstacles; // 障碍物列表
        private int _previousWindowHeight;

        // 输入相关字段
        private InputHandler _inputHandler;
        private SpriteFont _inputFont;

        // 构造函数，初始化图形设备管理器并设置内容目录
        public Base()
        {
            _graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            IsMouseVisible = true;
            // 设置初始窗口大小
            _graphics.PreferredBackBufferWidth = 1280;
            _graphics.PreferredBackBufferHeight = 720;
        }

        // 初始化方法，重写 Game 类的 Initialize 方法
        protected override void Initialize()
        {
            base.Initialize();
            _previousWindowHeight = GraphicsDevice.Viewport.Height;
            _inputHandler = new InputHandler();
        }

        // 加载内容方法，重写 Game 类的 LoadContent 方法
        protected override void LoadContent()
        {
            _spriteBatch = new SpriteBatch(GraphicsDevice);
            // 加载游戏内容
            Texture2D playerTexture = Content.Load<Texture2D>("player");
            Texture2D backgroundTexture = Content.Load<Texture2D>("background");
            Texture2D obstacleTexture = Content.Load<Texture2D>("obstacle");
            SpriteFont gameFont = Content.Load<SpriteFont>("GameFont");
            _inputFont = Content.Load<SpriteFont>("GameFont");

            // 初始化玩家实例
            _player = new Player(playerTexture, GraphicsDevice);

            // 初始化摄影机实例
            _camera = new Camera(GraphicsDevice.Viewport);

            // 初始化动态背景实例
            _dynamicBackground = new DynamicBackground(backgroundTexture, GraphicsDevice.Viewport);

            // 初始化调试覆盖实例
            _debugOverlay = new DebugOverlay(gameFont);

            // 更新缩放比例
            TextureManager.UpdateScale(GraphicsDevice.Viewport.Height);

            // 初始化障碍物列表为空，防止 Update 方法中空引用
            _obstacles = new List<Obstacle>();
        }

        // 更新方法，重写 Game 类的 Update 方法
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            if (_inputHandler.IsInputActive)
            {
                if (_inputHandler.HandleInput())
                {
                    StartGame(_inputHandler.InputText);
                }
            }
            else
            {
                // 检测窗口高度变化
                int currentWindowHeight = GraphicsDevice.Viewport.Height;
                if (currentWindowHeight != _previousWindowHeight)
                {
                    TextureManager.UpdateScale(currentWindowHeight);
                    _camera.UpdateViewport(GraphicsDevice.Viewport);
                    _dynamicBackground.Update(GraphicsDevice.Viewport, _player.Position);
                    _previousWindowHeight = currentWindowHeight;
                }

                // 确保_player 和 _obstacles 已初始化
                if (_player != null && _obstacles != null)
                {
                    _player.Update(gameTime, _obstacles.Select(o => o.CollisionBox).ToArray());
                    _camera.Follow(_player.Position, new Vector2(_player.Texture.Width, _player.Texture.Height) * TextureManager.Scale);
                    _dynamicBackground.Update(GraphicsDevice.Viewport, _player.Position);
                }
            }

            base.Update(gameTime);
        }

        private void StartGame(string seedText)
        {
            // 使用 SHA256 生成稳定的种子值
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(seedText));
                int seed = BitConverter.ToInt32(hashBytes, 0); // 提取前4字节作为种子值
                                                               // 打印 seed 值用于调试
                Console.WriteLine($"Generated Seed: {seed}");

                Texture2D obstacleTexture = Content.Load<Texture2D>("obstacle");
                List<Vector2> obstaclePositions = ObstacleGenerator.GenerateObstacles(seed, _player.Position, new Vector2(obstacleTexture.Width, obstacleTexture.Height), new Vector2(GraphicsDevice.Viewport.Width, GraphicsDevice.Viewport.Height));

                // 初始化障碍物列表
                _obstacles = obstaclePositions.Select(pos => new Obstacle(obstacleTexture, pos, GraphicsDevice)).ToList();
            }
        }

        // 绘制方法，重写 Game 类的 Draw 方法
        protected override void Draw(GameTime gameTime)
        {
            // 清除屏幕并设置背景色
            Color customColor = ColorHelper.FromHex("#ffffff");
            GraphicsDevice.Clear(customColor);

            _spriteBatch.Begin(transformMatrix: _camera.Transform, samplerState: SamplerState.PointClamp);
            if (!_inputHandler.IsInputActive)
            {
                _dynamicBackground?.Draw(_spriteBatch); // 绘制动态背景

                // 绘制障碍物
                if (_obstacles != null)
                {
                    foreach (var obstacle in _obstacles)
                    {
                        obstacle.Draw(_spriteBatch);
                    }
                }

                _player?.Draw(_spriteBatch); // 绘制玩家
            }
            _spriteBatch.End();

            if (_inputHandler.IsInputActive)
            {
                _spriteBatch.Begin();
                _spriteBatch.DrawString(_inputFont, "Enter Seed: " + _inputHandler.InputText, new Vector2(100, 100), Color.Black);
                _spriteBatch.End();
            }
            else
            {
                // 绘制调试信息
                _spriteBatch.Begin();
                if (_player != null)
                {
                    Vector2 playerPosition = CoordinateSystem.GetPlayerPosition(_player.Position + new Vector2(_player.Texture.Width, _player.Texture.Height) * TextureManager.Scale / 2);
                    _debugOverlay?.Draw(_spriteBatch, _dynamicBackground.TileCount, playerPosition);
                }
                _spriteBatch.End();
            }

            base.Draw(gameTime);
        }

        // 释放资源的方法，重写 Game 类的 Dispose 方法
        protected override void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    // 释放托管资源
                    _spriteBatch?.Dispose();
                    _graphics?.Dispose();
                }

                _disposed = true;
            }

            // 调用基类的 Dispose 方法
            base.Dispose(disposing);
        }

        // 析构函数，确保对象被垃圾回收时释放资源
        ~Base()
        {
            Dispose(false);
        }

        // 显式实现 IDisposable 接口的 Dispose 方法
        void IDisposable.Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
    }
}