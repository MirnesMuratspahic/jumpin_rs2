using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace JumpIn.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddVipCancelAtPeriodEnd : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "VipCancelAtPeriodEnd",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "VipCancelAtPeriodEnd",
                table: "Users");
        }
    }
}
