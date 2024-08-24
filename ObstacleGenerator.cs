using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using System.Linq;
namespace Boat
{
    public static class ObstacleGenerator
    {
        public static List<Vector2> GenerateObstaclesForClosedLoop(int seed, int obstacleCount, float radius, float obstacleSize, int windowHeight)
        {
            List<Vector2> positions = new List<Vector2>();
            Random random = new Random(seed);

            int gridSize = 64; // 设定网格大小为64像素

            // 使用动态计算的 gridSize 生成初始种子点
            positions = GenerateInitialSeedPoints(seed, obstacleCount, radius, obstacleSize, gridSize);

            // 填充相邻点之间的连接，确保形成封闭环路
            List<Vector2> filledPositions = FillConnectionsBetweenPoints(positions, gridSize, random);

            return filledPositions;
        }

        // 修改 GenerateInitialSeedPoints 方法的签名，以接收 gridSize
        private static List<Vector2> GenerateInitialSeedPoints(int seed, int obstacleCount, float radius, float obstacleSize, int gridSize)
        {
            List<Vector2> seedPoints = new List<Vector2>();
            Random random = new Random(seed);

            // 这里使用 gridSize 进行位置计算
            for (int i = 0; i < obstacleCount; i++)
            {
                float angle = MathHelper.ToRadians((360f / obstacleCount) * i);
                float x = radius * (float)Math.Cos(angle) + random.Next(-gridSize, gridSize);
                float y = radius * (float)Math.Sin(angle) + random.Next(-gridSize, gridSize);
                seedPoints.Add(new Vector2(x, y));
            }

            return seedPoints;
        }

        // 对相邻点之间进行填充，并形成封闭环路
        private static List<Vector2> FillConnectionsBetweenPoints(List<Vector2> positions, float obstacleSize, Random random)
        {
            List<Vector2> filledPositions = new List<Vector2>();
            int gridSize = 64; // 设定网格大小为64像素

            for (int i = 0; i < positions.Count; i++)
            {
                Vector2 startPoint = positions[i];
                Vector2 endPoint = positions[(i + 1) % positions.Count];

                // 计算水平和垂直方向上的差异
                float deltaX = endPoint.X - startPoint.X;
                float deltaY = endPoint.Y - startPoint.Y;

                // 水平移动
                int stepsX = (int)(Math.Abs(deltaX) / gridSize);
                int directionX = deltaX > 0 ? 1 : -1;
                for (int j = 0; j < stepsX; j++)
                {
                    Vector2 currentPosition = new Vector2(
                        startPoint.X + directionX * j * gridSize,
                        startPoint.Y
                    );
                    currentPosition.X = (float)Math.Round(currentPosition.X / gridSize) * gridSize;
                    currentPosition.Y = (float)Math.Round(currentPosition.Y / gridSize) * gridSize;

                    filledPositions.Add(currentPosition);
                }

                // 垂直移动
                int stepsY = (int)(Math.Abs(deltaY) / gridSize);
                int directionY = deltaY > 0 ? 1 : -1;
                for (int j = 0; j <= stepsY; j++)
                {
                    Vector2 currentPosition = new Vector2(
                        startPoint.X + directionX * stepsX * gridSize,
                        startPoint.Y + directionY * j * gridSize
                    );
                    currentPosition.X = (float)Math.Round(currentPosition.X / gridSize) * gridSize;
                    currentPosition.Y = (float)Math.Round(currentPosition.Y / gridSize) * gridSize;

                    filledPositions.Add(currentPosition);
                }
            }

            return filledPositions;
        }

        public static int GenerateCountFromHash(string hashInput, int maxCount)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(hashInput));
                return GetIntFromHash(hash, 0) % maxCount + 1;
            }
        }

        public static List<Vector2> GenerateObstacles(int seed, Vector2 playerPosition, Vector2 obstacleSize, Vector2 areaSize,int windowHeight)
        {
            int obstacleCount = GenerateCountFromHash(seed.ToString(), 100); // 仍然可以根据种子生成障碍物数量
            float radius = areaSize.X / 3; // 调整这个值以设置洞穴的平均半径
            float irregularity = 0.3f; // 调整这个值以增加或减少不规则性

            return GenerateObstaclesForClosedLoop(seed, obstacleCount, radius, irregularity, windowHeight);
        }

        private static float GetFloatFromHash(byte[] hash, int index)
        {
            // 确保索引不会超出哈希数组的长度
            index = index % (hash.Length - sizeof(uint));
            return BitConverter.ToUInt32(hash, index) / (float)uint.MaxValue;
        }

        private static int GetIntFromHash(byte[] hash, int startIndex)
        {
            // 确保索引不会超出哈希数组的长度
            startIndex = startIndex % (hash.Length - sizeof(int));
            return BitConverter.ToInt32(hash, startIndex) & int.MaxValue;
        }
    }
}