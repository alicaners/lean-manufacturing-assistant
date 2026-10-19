using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LeanAssistant.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUserScope : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "FactoryId",
                table: "Users",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "LineId",
                table: "Users",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_FactoryId",
                table: "Users",
                column: "FactoryId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_FactoryId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "FactoryId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LineId",
                table: "Users");
        }
    }
}
